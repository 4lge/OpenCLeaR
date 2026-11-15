## ----setup, include=FALSE-----------------------------------------------------
knitr::opts_chunk$set(echo = TRUE, warning = FALSE, message = FALSE)
library(OpenCLeaR)
library(ggplot2)


## ----opencl_kernel------------------------------------------------------------
diffusion_kernel <- '
// -*- c -*-

__kernel void diffusion_advection_3d(
    __global const real* c_input,     
    __global real* c_output,          
    __global const real* dem_mask,    
    const int nx,                     
    const int ny,                     
    const int nz,                     
    const real dt,                    
    const real dx,                    
    const real diff_coeff,            
    const real wind_x,                
    const real wind_y,                
    const real wind_z,
    const int source_x,
    const int source_y,
    const int source_z,
    const int base_seed,
    const int t)                
{
    int i = get_global_id(0); 
    int global_m = get_global_id(1); 

    if (i >= nx || global_m >= (ny * nz)) return;

    int k = global_m / ny; 
    int j = global_m % ny; 

    int current_idx = k * (nx * ny) + j * nx + i;
    int n_plane = nx * ny;

    // Solid terrain masking (DEM constraint)
    if (dem_mask[current_idx] <= 0.0f) {
        c_output[current_idx] = 0.0f;
        return;
    }

    real c_center = c_input[current_idx];

    // Neighborhood stencil acquisition with active boundary fallback
    real c_west  = (i > 0)      ? c_input[current_idx - 1]       : c_center;
    real c_east  = (i < nx - 1) ? c_input[current_idx + 1]       : c_center;
    real c_south = (j > 0)      ? c_input[current_idx - nx]      : c_center;
    real c_north = (j < ny - 1) ? c_input[current_idx + nx]      : c_center;
    real c_down  = (k > 0)      ? c_input[current_idx - n_plane] : c_center;
    real c_up    = (k < nz - 1) ? c_input[current_idx + n_plane] : c_center;

    // Neumann boundary conditions for complex topographies (Zero-Flux bounce back)
    if (i > 0      && dem_mask[current_idx - 1]       <= 0.0f) c_west  = c_center;
    if (i < nx - 1 && dem_mask[current_idx + 1]       <= 0.0f) c_east  = c_center;
    if (j > 0      && dem_mask[current_idx - nx]      <= 0.0f) c_south = c_center;
    if (j < ny - 1 && dem_mask[current_idx + nx]      <= 0.0f) c_north = c_center;
    if (k > 0      && dem_mask[current_idx - n_plane] <= 0.0f) c_down  = c_center;
    if (k < nz - 1 && dem_mask[current_idx + n_plane] <= 0.0f) c_up    = c_center;

    // 2.1. Spatial Laplacian derivative evaluation
    real laplacian = (c_east + c_west + c_north + c_south + c_up + c_down - 6.0f * c_center) / (dx * dx);

    // 2.2. Upwind directional advective derivative evaluation
    real adv_x = (wind_x >= 0.0f) ? (wind_x * (c_center - c_west) / dx)  : (wind_x * (c_east - c_center) / dx);
    real adv_y = (wind_y >= 0.0f) ? (wind_y * (c_center - c_south) / dx) : (wind_y * (c_north - c_center) / dx);
    real adv_z = (wind_z >= 0.0f) ? (wind_z * (c_center - c_down) / dx)  : (wind_z * (c_up - c_center) / dx);

    // Explicit temporal integration forward step
    real c_next = c_center + dt * (diff_coeff * laplacian - (adv_x + adv_y + adv_z));
    if (c_next < 0.0f) c_next = 0.0f;

    // Stochastic continuous point-source injection with extreme fluctuations
    if (i == source_x && j == source_y && k == source_z) {
        INIT_MT(base_seed + t);
        
        real rand_val = runif(0.0f, 1.0f);
        
        // Cubic scaling skews probability towards zero while provoking massive bursts
        real dynamic_source = 1200.0f * (rand_val * rand_val * rand_val);
        
        if (dynamic_source < 5.0f) dynamic_source = 2.0f; // Minimal background emission
        
        c_next += dynamic_source;
    }

    c_output[current_idx] = c_next;
}
'


## ----cpp_interface------------------------------------------------------------
diffusion_interface <- '
// Extract R input arrays and discrete layer dimensions
NumericVector r_c_init(r_c_start);
NumericVector r_dem(r_dem_mask);  

int nx = as<int>(r_nx);
int ny = as<int>(r_ny);
int nz = as<int>(r_nz);
int n_total = nx * ny * nz;
int steps = as<int>(r_iterations);

real dt         = as<real>(r_dt);
real dx         = as<real>(r_dx);
real diff_coeff = as<real>(r_diff_coeff);

// Baseline meteorological wind vectors from R session
real base_wind_x = as<real>(r_wind_x);
real base_wind_y = as<real>(r_wind_y);
real wind_z      = as<real>(r_wind_z); 

// Compute the scalar horizontal velocity magnitude
real wind_speed = sqrt(base_wind_x * base_wind_x + base_wind_y * base_wind_y);

// Localized stack emission source constraints
int source_x = nx / 2;
int source_y = ny / 2;
int source_z = 10;

Environment e = Environment::global_env();
std::vector<int> r_seed = e[".Random.seed"];

// Extract the active hardware-level random seed using the precise state pointer
int base_seed = r_seed[r_seed[1]+1];

// Extract the global temporal step offset to synchronize block transitions
int t_offset = as<int>(t);

// Allocate mirror VRAM memory buffers on the accelerator device (Ping-Pong framework)
Memory<real> gpu_c_puffer_A(*device, n_total);
Memory<real> gpu_c_puffer_B(*device, n_total);
Memory<real> gpu_dem_mask(*device, n_total);

for (int i = 0; i < n_total; ++i) {
    gpu_c_puffer_A[i] = (real)r_c_init[i];
    gpu_c_puffer_B[i] = (real)0.0;
    gpu_dem_mask[i]   = (real)r_dem[i];
}

gpu_c_puffer_A.write_to_device();
gpu_c_puffer_B.write_to_device();
gpu_dem_mask.write_to_device();

ulong grid_N = (ulong)nx;
ulong grid_M = (ulong)(ny * nz);
  
for (int t_loop = 0; t_loop < steps; ++t_loop) {
    int current_t = t_loop;
    
    // Instationary horizontal wind vector rotation profile
    // The angle advances continuously across streaming block boundaries
    real current_angle = (real)(t_offset + t_loop) * 0.002f; 
    
    real dynamic_wind_x = wind_speed * cos(current_angle);
    real dynamic_wind_y = wind_speed * sin(current_angle);
    
    if (t_loop % 2 == 0) {
        Kernel k(*device, grid_N, grid_M, WORKGROUP_SIZE, "diffusion_advection_3d",
                 gpu_c_puffer_A, gpu_c_puffer_B, gpu_dem_mask,
                 nx, ny, nz, dt, dx, diff_coeff, dynamic_wind_x, dynamic_wind_y, wind_z,
                 source_x, source_y, source_z, base_seed, current_t);
        k.run();
    } else {
        Kernel k(*device, grid_N, grid_M, WORKGROUP_SIZE, "diffusion_advection_3d",
                 gpu_c_puffer_B, gpu_c_puffer_A, gpu_dem_mask,
                 nx, ny, nz, dt, dx, diff_coeff, dynamic_wind_x, dynamic_wind_y, wind_z,
                 source_x, source_y, source_z, base_seed, current_t);
        k.run();
    }
}

NumericVector r_c_final(n_total);
if (steps % 2 == 0) {
    gpu_c_puffer_A.read_from_device();
    for (int i = 0; i < n_total; ++i) r_c_final[i] = gpu_c_puffer_A[i];
} else {
    gpu_c_puffer_B.read_from_device();
    for (int i = 0; i < n_total; ++i) r_c_final[i] = gpu_c_puffer_B[i];
}

Function f("runif"); f(1);
return r_c_final;
'


## ----compile_ocl_function-----------------------------------------------------
# Flush strings to physical disk structures
writeLines(diffusion_kernel, "./diffusion.cl")
writeLines(diffusion_interface, "./diffusion.cpp")

if (getRversion() >= "2.15.1") {
  utils::globalVariables(".diffusion_internal")
}

diffusion3D <- (function() {
  .diffusion_internal <- NULL
  
  function(r_c_start, r_dem_mask, r_nx, r_ny, r_nz, r_iterations, r_dt, r_dx, r_diff_coeff, r_wind_x, r_wind_y, r_wind_z, t, ...) { 
    
    if (is.null(.diffusion_internal)) {
      .diffusion_internal <<- OpenCLeaR::oclFunction(
        signature = methods::signature(
          r_c_start    = "numeric", r_dem_mask   = "numeric",
          r_nx         = "integer", r_ny         = "integer", r_nz = "integer",
          r_iterations = "integer", r_dt         = "numeric", r_dx = "numeric",
          r_diff_coeff = "numeric", r_wind_x     = "numeric", r_wind_y = "numeric", r_wind_z = "numeric",
          source_x     = "integer", source_y     = "integer", source_z = "integer",
          base_seed    = "integer", 
          t            = "integer"
        ),
        kernel_file    = "./diffusion.cl",
        interface_file = "./diffusion.cpp",
        force_float = TRUE
      )
    }
    return(.diffusion_internal(r_c_start, r_dem_mask, r_nx, r_ny, r_nz, r_iterations, r_dt, r_dx, r_diff_coeff, r_wind_x, r_wind_y, r_wind_z, t, ...))
  }
})()


## ----data_preparation---------------------------------------------------------
# Activate hardware accelerator context
ActivateDevice()
GetActiveDeviceInfo()

# 1. Structural dimensions constraint definition
# those settings work in terms of GPU memory size but will kill rgl 
# nx <- 580L   # X-Axis grid limits (West -> East)
# ny <- 580L   # Y-Axis grid limits (South -> North)
# nz <- 160L    # Z-Axis grid limits (Vertical Elevation)
# use this for a more fluent run without crashing the rgl plots
nx <- 120L   # X-Axis grid limits (West -> East)
ny <- 120L   # Y-Axis grid limits (South -> North)
nz <- 40L    # Z-Axis grid limits (Vertical Elevation)
n_total <- nx * ny * nz

dx <- 1.25    # Spatial resolution metric (2.5m voxel cube spacing)
#dx <- 5    # Spatial resolution metric (2.5m voxel cube spacing)
dt <- 0.1    # Temporal resolution metric (0.1s time-step increments)

# 2. Digital Elevation Model (DEM) masking setup
# Constructing a symmetrical Gaussian hill topographic layout at the domain center
dem_mask <- array(1.0, dim = c(nx, ny, nz))
center_x <- nx / 2
center_y <- ny / 2

for (x in 1:nx) {
  for (y in 1:ny) {
    dist_sq <- (x - center_x)^2 + (y - center_y)^2
    hill_height <- 8 * exp(-dist_sq / 150) # Peak height locked to 8 vertical voxels
    
    if (hill_height > 0) {
      max_solid_z <- min(nz, floor(hill_height))
      if (max_solid_z > 0) {
        # Define subsurface structures as non-permeable elements (0.0)
        dem_mask[x, y, 1:max_solid_z] <- 0.0
      }
    }
  }
}

# 3. Mass concentration matrix seed setup
# Positioning a continuous source stack directly over the topographic peak
c_start <- array(0.0, dim = c(nx, ny, nz))
source_x <- as.integer(center_x)
source_y <- as.integer(center_y)
source_z <- 10L 

c_start[source_x, source_y, source_z] <- 500.0

# 4. Serialize multi-dimensional configurations into linearized 1D arrays
c_start_flat <- as.numeric(c_start)
dem_mask_flat <- as.numeric(dem_mask)


## ----test_gpu_run-------------------------------------------------------------
# Configure meteorological baseline parameters
iterations <- 2000L
diff_coeff <- 1.5      
wind_x     <- 4.0      # Dominant westerly breeze profile
wind_y     <- 0.5      
wind_z     <- 0.2      

s_x  <- as.integer(nx / 2)
s_y  <- as.integer(ny / 2)
s_z  <- 10L
seed_init <- 12345L
t_init    <- 0L

cat("🎬 Launching monolithic 3D voxel advection-diffusion pipeline on the GPU...\n")
t_start <- Sys.time()

c_final_flat <- diffusion3D(
  r_c_start    = c_start_flat, 
  r_dem_mask   = dem_mask_flat,
  r_nx         = nx, 
  r_ny         = ny, 
  r_nz         = nz,
  r_iterations = iterations, 
  r_dt         = dt, 
  r_dx         = dx,
  r_diff_coeff = diff_coeff, 
  r_wind_x     = wind_x, 
  r_wind_y     = wind_y, 
  r_wind_z     = wind_z,
  source_x     = s_x,          
  source_y     = s_y,          
  source_z     = s_z,          
  base_seed    = seed_init,    
  t            = t_init        
)

t_end <- Sys.time()
cat("✅ Core task terminated! Absolute GPGPU device computing time:", round(as.numeric(t_end - t_start), 4), "seconds.\n")

c_final <- array(c_final_flat, dim = c(nx, ny, nz))


## ----static_2d_plot-----------------------------------------------------------
z_slice <- 10
slice_data <- c_final[, , z_slice]

# Render the dispersion footprint within the ambient flow field
image(
  x = 1:nx, y = 1:ny, z = slice_data,
  col = terrain.colors(100),
  main = paste("Horizontal Dispersion Footprint (Vertical Layer z =", z_slice, ")"),
  xlab = "X-Axis: West -> East (Grid Units)",
  ylab = "Y-Axis: South -> North (Grid Units)"
)
contour(x = 1:nx, y = 1:ny, z = slice_data, add = TRUE, col = "black")


## ----rgl_interactive_loop, echo=TRUE, eval=TRUE-------------------------------
library(rgl)
close3d()

# 1. Window initialization: Instantiating a large display canvas
open3d(windowRect = c(100, 100, 1100, 900))
bg3d("black") 

# 2. Viewport alignment: Orienting camera diagonally from front-top
view3d(theta = 0, phi = 35, zoom = 0.82, fov = 30)

# Coordinate grid generation for voxel spaces (Synchronized to OpenCL layout)
coords <- expand.grid(x = 1:nx, y = 1:ny, z = 1:nz)

total_steps <- 2000L
n0 <- 50L  
current_state <- c_start_flat

s_x  <- as.integer(nx / 2)
s_y  <- as.integer(ny / 2)
s_z  <- 10L
seed_init <- 12345L

# Extract un-distorted elevation matrices for the wireframe mesh topography
dem_array <- array(dem_mask_flat, dim = c(nx, ny, nz))
dem_surface <- apply(dem_array, c(1, 2), function(v) {
  solid_layers <- which(v == 0.0) # Identify solid subsurface boundary voxels
  if (length(solid_layers) > 0) {
    return(max(solid_layers))
  } else {
    return(0)
  }
})

# Execute the segmented hardware-to-host streaming loop
for (block in seq(1, total_steps, by = n0)) {
  
  # Compute phase: Execute n0 steps autonomously on the GPGPU accelerator
  current_state <- diffusion3D(
    r_c_start    = current_state, 
    r_dem_mask   = dem_mask_flat,
    r_nx         = nx, r_ny = ny, r_nz = nz,
    r_iterations = n0, 
    r_dt = dt, r_dx = dx, r_diff_coeff = diff_coeff, 
    r_wind_x = wind_x, r_wind_y = wind_y, r_wind_z = wind_z,
    source_x     = s_x,        
    source_y     = s_y,        
    source_z     = s_z,        
    base_seed    = seed_init,  
    t            = as.integer(block) # Pass global offset step to drive wind rotation
  )
  
  # Rendering phase: Defer redrawing to prevent screen flickering
  par3d(skipRedraw = TRUE)
  
  clear3d() 
  
  # Orientation bounding box mapping
  bbox3d(
    xat = seq(0, nx, by = 20), yat = seq(0, nz, by = 10), zat = seq(0, ny, by = 20),
    color = "#888888", emission = "#444444", draw_labels = TRUE
  )
  
  # Explicit parameter mapping layout ensures the DEM mesh lies flat on the canvas
  # RGL-X = Width, RGL-Y = Matrix Height (Y-Argument), RGL-Z = Depth (Z-Argument)
  surface3d(
    x = 1:nx, z = 1:ny, y = dem_surface,
    color = "#444444", alpha = 0.5, front = "lines", back = "lines"
  )

  # Display the live iteration counter on the physiscal backwall (Z = 1)
  text3d(
    x = nx / 2, y = nz + 4, z = 1,
    texts = paste("Iteration:", block),
    color = "white", cex = 2.5, adj = c(0.5, 0), font = 2
  )

  # Pollutant Cloud: Filter out sub-threshold concentrations for crisp visualization
  visible_idx <- which(current_state > 0.1 & dem_mask_flat > 0.0)
  
  if (length(visible_idx) > 0) {
    voxel_coords <- coords[visible_idx, ]
    voxel_values <- current_state[visible_idx]
    
    # Log-transform concentrations to resolve high spatial dynamic ranges
    log_values <- log(voxel_values + 1.0)
    max_log <- max(log_values)
    if(max_log <= 0) max_log <- 1.0
    
    color_indices <- cut(log_values, breaks = 100)
    color_palette <- heat.colors(100)
    voxel_colors  <- color_palette[color_indices]
    
    # High base opacity accentuates dense plume cores while keeping edges translucent
    dynamic_alpha = 0.40 + 0.55 * (log_values / max_log)
    
    # Map points symmetrically onto the flat spatial canvas system
    points3d(
      voxel_coords$x, voxel_coords$z, voxel_coords$y, 
      color = voxel_colors, size = 8, alpha = dynamic_alpha, lit = TRUE
    )
    
    # Emphasize source origin point (Emission Stack)
    points3d(s_x, s_z, s_y, color = "cyan", size = 10, lit = FALSE)
  }
  
  par3d(skipRedraw = FALSE)
  
  # Host memory cleanup allocation
  rm(visible_idx)
  gc(verbose = FALSE)
}

# Freeze and serialize the active geometric scene structure into global memory
final_scene <<- rgl::scene3d()


## ----rgl_html_widget, echo=FALSE, eval=TRUE-----------------------------------
# Render the serialized scene structure using absolute pixel dimension scales
library(rgl)
if (exists("final_scene")) {
  rglwidget(final_scene, width = 900, height = 650)
} else {
  cat("⚠️ Active scene graph allocation missing in global R memory context.")
}

