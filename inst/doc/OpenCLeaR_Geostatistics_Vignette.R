## ----setup, include=FALSE-----------------------------------------------------
knitr::opts_chunk$set(echo = TRUE, warning = FALSE, message = FALSE)
library(OpenCLeaR)
library(ggplot2)


## ----hardware_diagnostics-----------------------------------------------------
ActivateDevice()
GetActiveDeviceInfo()


## ----create_kernel_source-----------------------------------------------------
kernel_src <- '
// -*- c -*-

#define atomic_add(a,b) atomic_add_global((a),(b)) 

#if REALDOUBLES        
    #pragma OPENCL EXTENSION cl_khr_fp64 : enable
    #ifdef cl_khr_int64_base_atomics
        #pragma OPENCL EXTENSION cl_khr_int64_base_atomics : enable
    #endif
    #define UINTVAR ulong
    #define AS_INT as_ulong
    #define AS_REAL as_double
    #define REAL double
    #define ATOM_CMPXCHG atom_cmpxchg 
#else   
    #ifdef cl_khr_local_int32_base_atomics
        #pragma OPENCL EXTENSION cl_khr_local_int32_base_atomics : enable
    #endif
    #ifdef cl_khr_global_int32_base_atomics
        #pragma OPENCL EXTENSION cl_khr_global_int32_base_atomics : enable
    #endif
    #define UINTVAR uint
    #define AS_INT as_uint
    #define AS_REAL as_float
    #define REAL float
    #define ATOM_CMPXCHG atomic_cmpxchg
#endif

inline void atomic_add_global(volatile global REAL * const source, const REAL operand) {
    UINTVAR expected, current;
    current = AS_INT(*source);
    do {
        expected = current;
        current = ATOM_CMPXCHG((volatile global UINTVAR *)source, expected, AS_INT(AS_REAL(expected) + operand));
    } while (current != expected);
}

__kernel void calc_experimental_variogram(
    __global const real* x_coords,
    __global const real* y_coords,
    __global const real* values,
    __global real* bin_sums,
    __global int* bin_counts,
    const int num_points,
    const real lag_distance,
    const int num_bins) 
{
    int i = get_global_id(0);

    if (i < num_points) {
        real x1 = x_coords[i];
        real y1 = y_coords[i];
        real val1 = values[i];

        // Linearized 1D pair tracking loop matching sequential CPU routines
        for (int j = i + 1; j < num_points; ++j) {
            real dx = x1 - x_coords[j];
            real dy = y1 - y_coords[j];
            real dist = sqrt(dx * dx + dy * dy);
            
            int bin_idx = (int)(dist / lag_distance);
            
            if (bin_idx >= 0 && bin_idx < num_bins) {
                real val_diff = val1 - values[j];
                real sq_diff = val_diff * val_diff;
                
                atomic_inc(&bin_counts[bin_idx]);
                atomic_add(&bin_sums[bin_idx], sq_diff);
            }
        }
    }
}
'
writeLines(kernel_src, "./variogram.cl")


## ----create_interface_source--------------------------------------------------
interface_src <- '
int total_points = as<int>(n_points);
int num_bins_typed = as<int>(num_bins);
real lag_dist_typed = as<real>(lag_distance);

NumericVector r_x(x_coords);
NumericVector r_y(y_coords);
NumericVector r_z(values);

// Allocate Rcpp result elements
NumericVector out_sums(num_bins_typed);
IntegerVector out_counts(num_bins_typed);

Memory<real> GpuX(*device, total_points);
Memory<real> GpuY(*device, total_points);
Memory<real> GpuZ(*device, total_points);
Memory<real> GpuSums(*device, num_bins_typed);
Memory<int>  GpuCounts(*device, num_bins_typed);

for(int i = 0; i < total_points; ++i) {
    GpuX[i] = (real)r_x[i];
    GpuY[i] = (real)r_y[i];
    GpuZ[i] = (real)r_z[i];
}
for(int i = 0; i < num_bins_typed; ++i) {
    GpuSums[i] = (real)0.0;
    GpuCounts[i] = 0;
}

GpuX.write_to_device();
GpuY.write_to_device();
GpuZ.write_to_device();
GpuSums.write_to_device();
GpuCounts.write_to_device();

Kernel var_kernel(*device, total_points, "calc_experimental_variogram",
                  GpuX, GpuY, GpuZ, GpuSums, GpuCounts, total_points, lag_dist_typed, num_bins_typed);
var_kernel.run();

GpuSums.read_from_device();
GpuCounts.read_from_device();

for(int i = 0; i < num_bins_typed; ++i) {
    out_sums[i] = GpuSums[i];
    out_counts[i] = GpuCounts[i];
}

return List::create(
    _["bin_sums"]   = out_sums,
    _["bin_counts"] = out_counts
);
'
writeLines(interface_src, "./variogram.cpp")


## ----compile_pipeline---------------------------------------------------------
if (getRversion() >= "2.15.1") {
  utils::globalVariables(".variogram_ocl_internal")
}

variogramOCL <- (function() {
  .variogram_ocl_internal <- NULL
  
  function(x_coords, y_coords, values, n_points, lag_distance, num_bins, ...) {
    if (is.null(.variogram_ocl_internal)) {
      .variogram_ocl_internal <<- OpenCLeaR::oclFunction(
        signature = methods::signature(
          x_coords     = "numeric",
          y_coords     = "numeric",
          values       = "numeric",
          n_points     = "integer",
          lag_distance = "numeric",
          num_bins     = "integer"
        ),
        kernel_file    = "./variogram.cl",
        interface_file = "./variogram.cpp",
        force_float    = TRUE,
        ...
      )
    }
    return(.variogram_ocl_internal(x_coords, y_coords, values, n_points, lag_distance, num_bins))
  }
})()


## ----simulate_spatial_field---------------------------------------------------
set.seed(42)
n_points <- 60000L

# Metrics coordinates representing spatial tracking zones [Meters]
x <- runif(n_points, min = 0, max = 10000)
y <- runif(n_points, min = 0, max = 10000)

# Simulate structural spatial signal wave + Gaussian noise
z <- sin(x / 1500) * cos(y / 1500) + rnorm(n_points, sd = 0.15)

# Semivariance structural configuration
lag_d <- 400   # 400 Meters distance tracking interval
bins  <- 15    # Compute up to a maximum distance boundary of 6,000 Meters


## ----execute_gpu_computation--------------------------------------------------
cat("Launching combinatorial variogram estimation via OpenCLeaR on GPU...\n")
timer_start <- proc.time()

gpu_raw <- variogramOCL(
  x_coords     = x,
  y_coords     = y,
  values       = z,
  n_points     = as.integer(n_points),
  lag_distance = as.numeric(lag_d),
  num_bins     = as.integer(bins)
)

timer_end <- proc.time()
cat("Total hardware execution processing time:", (timer_end - timer_start)[3], "seconds.\n")


## ----plotting_variogram, fig.width=8, fig.height=5----------------------------
empirical_variogram <- data.frame(
  Lag_Center = (1:bins * lag_d) - (lag_d / 2),
  Pair_Count = gpu_raw$bin_counts,
  Semivario  = gpu_raw$bin_sums / (2 * gpu_raw$bin_counts)
)

# Render spatial structure signature
ggplot(empirical_variogram, aes(x = Lag_Center, y = Semivario)) +
  geom_line(color = "#2c3e50", linewidth = 1) +
  geom_point(color = "#e74c3c", size = 3) +
  labs(
    title = "Empirical Variogram Tracking Profile via OpenCLeaR",
    subtitle = paste("Computed from", n_points, "locations (", choose(n_points, 2), "combinatorial pair steps)"),
    x = "Distance (Lag Center) [m]",
    y = "Semivariance gamma(h)"
  ) +
  theme_minimal()


## ----create_cpp_fitting-------------------------------------------------------
fitting_src <- '
#include <RcppEigen.h>
#include <cmath>

// [[Rcpp::depends(RcppEigen)]]
// [[Rcpp::export]]
Rcpp::NumericVector fit_spherical_cpp(Rcpp::NumericVector lags, Rcpp::NumericVector semivariances, Rcpp::NumericVector start_params) {
    Eigen::VectorXd h = Rcpp::as<Eigen::VectorXd>(lags);
    Eigen::VectorXd y = Rcpp::as<Eigen::VectorXd>(semivariances);
    
    // Parameter: [0] = Nugget, [1] = Sill, [2] = Range
    Eigen::VectorXd p = Rcpp::as<Eigen::VectorXd>(start_params);
    
    int n = h.size();
    int max_iter = 100;
    double tolerance = 1e-6;
    
    for (int iter = 0; iter < max_iter; ++iter) {
        Eigen::VectorXd r(n);
        Eigen::MatrixXd J(n, 3);
        
        for (int i = 0; i < n; ++i) {
            double dist = h[i];
            if (dist <= p[2]) {
                double h_a = dist / p[2];
                r[i] = y[i] - (p[0] + p[1] * (1.5 * h_a - 0.5 * std::pow(h_a, 3.0)));
                
                J(i, 0) = 1.0; 
                J(i, 1) = 1.5 * h_a - 0.5 * std::pow(h_a, 3.0); 
                J(i, 2) = p[1] * (-1.5 * dist / std::pow(p[2], 2.0) + 1.5 * std::pow(dist, 3.0) / std::pow(p[2], 4.0)); 
            } else {
                r[i] = y[i] - (p[0] + p[1]);
                J(i, 0) = 1.0;
                J(i, 1) = 1.0;
                J(i, 2) = 0.0;
            }
        }
        
        Eigen::VectorXd delta = (J.transpose() * J).ldlt().solve(J.transpose() * r);
        p += delta;
        
        if (p[0] < 0.0) p[0] = 0.0;
        if (p[1] < 0.0) p[1] = 0.0;
        if (p[2] <= 0.0) p[2] = tolerance;
        
        if (delta.norm() < tolerance) break;
    }
    
    return Rcpp::wrap(p);
}
'
Rcpp::sourceCpp(code = fitting_src)


## ----execute_fitting_and_plot, fig.width=8, fig.height=5----------------------
# Define operational starting values for the Gauss-Newton loop
initial_guess <- c(0.01, var(z), 3000.0)

# Run the RcppEigen optimization pass
fitted_parameters <- fit_spherical_cpp(
  lags           = empirical_variogram$Lag_Center,
  semivariances  = empirical_variogram$Semivario,
  start_params   = initial_guess
)

fit_nugget <- fitted_parameters[1]
fit_sill   <- fitted_parameters[2]
fit_range  <- fitted_parameters[3]

cat(sprintf("📊 Fitted Nugget (c0): %.4f\nPartial Sill (c): %.4f\nRange (a): %.4f meters\n", 
            fit_nugget, fit_sill, fit_range))

# Generate a continuous evaluation line for the theoretical curve
fine_lags <- seq(0, max(empirical_variogram$Lag_Center), length.out = 200)
theoretical_curve <- data.frame(
  Lag_Center = fine_lags,
  Semivario  = ifelse(fine_lags <= fit_range,
                      fit_nugget + fit_sill * (1.5 * (fine_lags / fit_range) - 0.5 * (fine_lags / fit_range)^3),
                      fit_nugget + fit_sill)
)

ggplot() +
  geom_point(data = empirical_variogram, aes(x = Lag_Center, y = Semivario), 
             color = "#e74c3c", size = 3, stroke = 1.2) +
  geom_line(data = theoretical_curve, aes(x = Lag_Center, y = Semivario), 
            color = "#2c3e50", linewidth = 1.2) +
  labs(
    title = "Theoretical Spherical Variogram Optimization Profile",
    subtitle = "Gauss-Newton curve alignment matching discrete empirical GPU lags",
    x = "Distance (Lag Center) [m]", y = "Semivariance gamma(h)"
  ) +
  theme_minimal()


## ----create_kriging_kernel----------------------------------------------------
kriging_kernel_src <- '
// -*- c -*-

// GPU compute nodes cannot cope with large arrays, so be careful here:
#define MAX_NEIGHBORS 100

static inline real eval_spherical(real dist, real nugget, real sill, real range) {
    if (dist <= 0.0f) return 0.0f;
    if (dist >= range) return nugget + sill;
    real h_a = dist / range;
    return nugget + sill * (1.5f * h_a - 0.5f * h_a * h_a * h_a);
}

__kernel void ordinary_kriging_2d(
    __global const real* obs_x,
    __global const real* obs_y,
    __global const real* obs_z,
    __global real* kriging_surface,
    const int num_obs,
    const real min_x,
    const real min_y,
    const real cell_size,
    const int grid_rows,
    const int grid_cols,
    const real nugget,
    const real sill,
    const real range) 
{
    int col_idx = get_global_id(0); 
    int row_idx = get_global_id(1); 

    if (col_idx >= grid_cols || row_idx >= grid_rows) return;

    real pred_x = min_x + col_idx * cell_size;
    real pred_y = min_y + row_idx * cell_size;

    // =========================================================================
    // MODIFIZIERTE NACHBARSCHAFTSSUCHE (RADIUS + MAX_NEIGHBORS CAP)
    // =========================================================================
    real max_krig_dist = range * 1.2f;
    int nb_idx[MAX_NEIGHBORS];
    real nb_dist[MAX_NEIGHBORS];

    for (int i = 0; i < MAX_NEIGHBORS; ++i) {
        nb_dist[i] = 1e20f;
        nb_idx[i] = -1;
    }

    for (int i = 0; i < num_obs; ++i) {
        real dx = pred_x - obs_x[i];
        real dy = pred_y - obs_y[i];
        real d = sqrt(dx * dx + dy * dy);
        
        // 🛡️ RADIUS-BREMSE: Punkte außerhalb des Suchradius sofort überspringen
        if (d > max_krig_dist) {
            continue;
        }
        
        // Insertion Sort über das feste Register-Array
        for (int j = 0; j < MAX_NEIGHBORS; ++j) {
            if (d < nb_dist[j]) {
                for (int k = MAX_NEIGHBORS - 1; k > j; --k) {
                    nb_dist[k] = nb_dist[k - 1];
                    nb_idx[k] = nb_idx[k - 1];
                }
                nb_dist[j] = d;
                nb_idx[j] = i;
                break;
            }
        }
    }

    // Ermittle dynamisch, wie viele gültige Punkte tatsächlich im Radius lagen
    int n_comp = 0;
    for (int i = 0; i < MAX_NEIGHBORS; ++i) {
        if (nb_idx[i] != -1) n_comp++;
    }
    // =========================================================================

    int target_pixel_idx = row_idx * grid_cols + col_idx;

    // Falls gar kein Punkt im Suchradius liegt, weise einen sicheren Fallback-Wert zu
    if (n_comp == 0) {
        kriging_surface[target_pixel_idx] = 0.0f;
        return;
    }

    // 2. Erstellung der Kovarianzstrukturen für das GLS-Modell
    real Sigma[MAX_NEIGHBORS * MAX_NEIGHBORS];
    real b_z[MAX_NEIGHBORS];
    real A_design[MAX_NEIGHBORS]; 
    
    for (int i = 0; i < n_comp; ++i) {
        int idx_i = nb_idx[i];
        b_z[i] = obs_z[idx_i];
        A_design[i] = 1.0f; 
        
        for (int j = 0; j < n_comp; ++j) {
            int idx_j = nb_idx[j];
            real dx = obs_x[idx_i] - obs_x[idx_j];
            real dy = obs_y[idx_i] - obs_y[idx_j];
            real d_ij = sqrt(dx * dx + dy * dy);
            
            Sigma[i * n_comp + j] = (nugget + sill) - eval_spherical(d_ij, nugget, sill, range);
        }
    }

    // 3. Registerallokation für den libkernel.cl wls_gls_fit Workspace
    real x_out; 
    real workspace_A_tilde[MAX_NEIGHBORS];
    real workspace_b_tilde[MAX_NEIGHBORS];
    real workspace_L[MAX_NEIGHBORS * MAX_NEIGHBORS];
    real workspace_col[MAX_NEIGHBORS];
    real workspace_R[MAX_NEIGHBORS];
    real workspace_qty[MAX_NEIGHBORS];

    // 4. Direkter Aufruf der geladenen GLS-Funktion
    int status = wls_gls_fit(
        A_design, b_z, n_comp, 1, 
        Sigma, 0, &x_out,
        workspace_A_tilde, workspace_b_tilde, workspace_L, 
        workspace_col, workspace_R, workspace_qty
    );

    if (status != 0) {
        real mean_z = 0.0f;
        for (int k = 0; k < n_comp; ++k) mean_z += b_z[k];
        kriging_surface[target_pixel_idx] = mean_z / (real)n_comp;
        return;
    }

    // 5. Rechten-Seiten-Vektor (Kovarianz zum Vorhersagepunkt) aufbauen
    real c_pred[MAX_NEIGHBORS];
    for (int i = 0; i < n_comp; ++i) {
        c_pred[i] = (nugget + sill) - eval_spherical(nb_dist[i], nugget, sill, range);
    }

    // 6. Kriging-Gewichte über die Cholesky-Zerlegung (L) berechnen
    real cy[MAX_NEIGHBORS];
    core_forward_substitute(workspace_L, n_comp, c_pred, cy);
    
    real w_weights[MAX_NEIGHBORS];
    for (int i = n_comp - 1; i >= 0; i--) {
        real sum = cy[i];
        for (int j = i + 1; j < n_comp; j++) {
            sum -= workspace_L[j * n_comp + i] * w_weights[j];
        }
        w_weights[i] = sum / workspace_L[i * n_comp + i];
    }

    // 7. Finale Kombination aus Gewichten und Beobachtungen
    real z_pred = 0.0f;
    real weight_sum = 0.0f;
    for (int i = 0; i < n_comp; ++i) {
        z_pred += w_weights[i] * b_z[i];
        weight_sum += w_weights[i];
    }

    z_pred += (1.0f - weight_sum) * x_out;
    kriging_surface[target_pixel_idx] = z_pred;
}
'
writeLines(kriging_kernel_src, "./kriging.cl")


## ----create_kriging_interface-------------------------------------------------
kriging_interface_src <- '
int obs_count = as<int>(num_obs);
int rows      = as<int>(grid_rows);
int cols      = as<int>(grid_cols);
int total_pixels = rows * cols;

NumericVector r_obs_x(obs_x);
NumericVector r_obs_y(obs_y);
NumericVector r_obs_z(obs_z);
NumericMatrix out_matrix(rows, cols);

Memory<real> GpuObsX(*device, obs_count);
Memory<real> GpuObsY(*device, obs_count);
Memory<real> GpuObsZ(*device, obs_count);
Memory<real> GpuSurface(*device, total_pixels);

for(int i = 0; i < obs_count; ++i) {
    GpuObsX[i] = (real)r_obs_x[i];
    GpuObsY[i] = (real)r_obs_y[i];
    GpuObsZ[i] = (real)r_obs_z[i];
}

GpuObsX.write_to_device();
GpuObsY.write_to_device();
GpuObsZ.write_to_device();

Kernel krig_kernel(*device, cols, rows, WORKGROUP_SIZE, "ordinary_kriging_2d",
                   GpuObsX, GpuObsY, GpuObsZ, GpuSurface, obs_count,
                   as<real>(min_x), as<real>(min_y), as<real>(cell_size),
                   rows, cols, as<real>(nugget), as<real>(sill), as<real>(range));
krig_kernel.run();

GpuSurface.read_from_device();
for(int i = 0; i < total_pixels; ++i) {
    out_matrix[i] = GpuSurface[i];
}

return out_matrix;
'
writeLines(kriging_interface_src, "./kriging.cpp")


## ----register_kriging_pipeline------------------------------------------------
krigingOCL <- (function() {
  .kriging_internal <- NULL
  function(obs_x, obs_y, obs_z, num_obs, min_x, min_y, cell_size, grid_rows, grid_cols, nugget, sill, range) {
    if (is.null(.kriging_internal)) {
      .kriging_internal <<- OpenCLeaR::oclFunction(
        signature = methods::signature(
          obs_x = "numeric", obs_y = "numeric", obs_z = "numeric", num_obs = "integer",
          min_x = "numeric", min_y = "numeric", cell_size = "numeric",
          grid_rows = "integer", grid_cols = "integer",
          nugget = "numeric", sill = "numeric", range = "numeric"
        ),
        kernel_file    = "./kriging.cl",
        interface_file = "./kriging.cpp",
        force_float    = TRUE
      )
    }
    return(.kriging_internal(obs_x, obs_y, obs_z, num_obs, min_x, min_y, cell_size, grid_rows, grid_cols, nugget, sill, range))
  }
})()


## ----gpu_heavy_stress_test----------------------------------------------------
grid_size_heavy <- 3000L
cell_res_heavy  <- 3.333333

cat("🔥 Activating OpenCLeaR GPGPU Heavy Stress-Test (540 Billion Iterations)... \n")
invisible(krigingOCL(
  obs_x     = x,
  obs_y     = y,
  obs_z     = z,
  num_obs   = as.integer(n_points),
  min_x     = 0.0,
  min_y     = 0.0,
  cell_size = cell_res_heavy,
  grid_rows = grid_size_heavy,
  grid_cols = grid_size_heavy,
  nugget    = fit_nugget,
  sill      = fit_sill,
  range     = fit_range
))
cat("✅ VRAM registers saturated. Hardware pipelines ready for cross-validation.\n\n")


## ----execute_sub_sampled_variogram--------------------------------------------
# Define synchronized profiling boundaries
grid_size <- 100L
cell_res  <- 100.0 # Rescaled cell size to cleanly map the 10km grid domain

# Extract static, reproducible random indices for the validation sample
set.seed(123)
sub_idx <- sample(1:n_points, 500L)

sub_x <- x[sub_idx]
sub_y <- y[sub_idx]
sub_z <- z[sub_idx]

# 1. Compute empirical variogram bins for the 500-point subset via 1D GPU kernel
gpu_raw_sub <- variogramOCL(
  x_coords     = sub_x,
  y_coords     = sub_y,
  values       = sub_z,
  n_points     = 500L,
  lag_distance = as.numeric(lag_d),
  num_bins     = as.integer(bins)
)

empirical_variogram_sub <- data.frame(
  Lag_Center = (1:bins * lag_d) - (lag_d / 2),
  Pair_Count = gpu_raw_sub$bin_counts,
  Semivario  = gpu_raw_sub$bin_sums / (2 * gpu_raw_sub$bin_counts)
)

# 2. Fit customized theoretical parameters via RcppEigen for the subset
initial_guess_sub <- c(0.01, var(sub_z), 3000.0)
fitted_params_sub <- fit_spherical_cpp(
  lags           = empirical_variogram_sub$Lag_Center,
  semivariances  = empirical_variogram_sub$Semivario,
  start_params   = initial_guess_sub
)

fit_nugget_sub <- fitted_params_sub[1]
fit_sill_sub   <- fitted_params_sub[2]
fit_range_sub  <- fitted_params_sub[3]

cat(sprintf("📊 Sub-Sampled Fitted Nugget (c0): %.4f\nPartial Sill (c): %.4f\nRange (a): %.4f meters\n", 
            fit_nugget_sub, fit_sill_sub, fit_range_sub))


## ----plotting_variogram_comparison, fig.width=14, fig.height=6----------------
library(gridExtra)
# Generate continuous evaluation lines for the sub-sampled curve
fine_lags_sub <- seq(0, max(empirical_variogram_sub$Lag_Center), length.out = 200)
theoretical_curve_sub <- data.frame(
  Lag_Center = fine_lags_sub,
  Semivario  = ifelse(fine_lags_sub <= fit_range_sub,
                      fit_nugget_sub + fit_sill_sub * (1.5 * (fine_lags_sub / fit_range_sub) - 0.5 * (fine_lags_sub / fit_range_sub)^3),
                      fit_nugget_sub + fit_sill_sub)
)

plot_var_global <- ggplot() +
  geom_point(data = empirical_variogram, aes(x = Lag_Center, y = Semivario), color = "#e74c3c", size = 2.5) +
  geom_line(data = theoretical_curve, aes(x = Lag_Center, y = Semivario), color = "#2c3e50", linewidth = 1) +
  labs(title = "Global Variogram Model (60,000 Points)",
       x = "Distance [m]", y = "Semivariance") +
  theme_minimal()

plot_var_sub <- ggplot() +
  geom_point(data = empirical_variogram_sub, aes(x = Lag_Center, y = Semivario), color = "#3498db", size = 2.5) +
  geom_line(data = theoretical_curve_sub, aes(x = Lag_Center, y = Semivario), color = "#2c3e50", linewidth = 1) +
  labs(title = "Sub-Sampled Variogram Model (500 Points)",
       x = "Distance [m]", y = "Semivariance") +
  theme_minimal()

grid.arrange(plot_var_global, plot_var_sub, ncol = 2)


## ----run_kriging_gpu_production-----------------------------------------------
cat("🚀 Launching 2D Kriging on the GPU (OpenCLeaR, 500 points)... \n")
timer_gpu_start <- proc.time()

interpolated_surface_gpu <- krigingOCL(
  obs_x     = sub_x,
  obs_y     = sub_y,
  obs_z     = sub_z,
  num_obs   = 500L,
  min_x     = 0.0,
  min_y     = 0.0,
  cell_size = cell_res,
  grid_rows = grid_size,
  grid_cols = grid_size,
  nugget    = fit_nugget_sub,
  sill      = fit_sill_sub,
  range     = fit_range_sub
)

timer_gpu_end <- proc.time()
time_gpu_krig <- as.numeric((timer_gpu_end - timer_gpu_start)[3])
cat(sprintf("✅ GPU Processing finished in: %.4f seconds.\n\n", time_gpu_krig))


## ----run_kriging_gstat_cpu----------------------------------------------------
library(gstat)
library(sp)

# 1. Bypass sf geometry overhead: Bind directly to classic, lightweight sp structures
obs_df <- data.frame(x = sub_x, y = sub_y, z = sub_z)
sp::coordinates(obs_df) <- ~x+y

# 2. Build the prediction target grid as a plain SpatialPoints data frame
grid_df <- expand.grid(
  x = 1:grid_size * cell_res,
  y = 1:grid_size * cell_res
)
sp::coordinates(grid_df) <- ~x+y

# 3. Formulate the exact matching theoretical spherical variogram model
gstat_model <- gstat::vgm(
  psill  = fit_sill_sub,
  model  = "Sph",
  range  = fit_range_sub,
  nugget = fit_nugget_sub
)

# Calculate spatial search radius (Range + 20%)
search_radius <- fit_range_sub * 1.2

cat(sprintf("⏳ Launching Radius-Based 2D Kriging on the CPU (gstat, Radius: %.2f m)... \n", search_radius))
timer_cpu_start <- proc.time()

# Execute gstat ordinary kriging over classic sp objects
interpolated_surface_cpu <- gstat::krige(
  formula   = z ~ 1,
  locations = obs_df,
  newdata   = grid_df,
  model     = gstat_model,
  maxdist   = search_radius, 
  debug.level = 0
)

timer_cpu_end <- proc.time()
time_cpu_krig <- as.numeric((timer_cpu_end - timer_cpu_start)[3])
cat(sprintf("✅ CPU Processing finished in: %.4f seconds.\n", time_cpu_krig))


## ----plotting_comparison, fig.width=14, fig.height=6--------------------------
# 1. Quantify the maximum numerical discrepancy between the two backends
res_gpu_vec <- as.vector(interpolated_surface_gpu)
res_cpu_vec <- interpolated_surface_cpu$var1.pred

max_krig_diff <- max(abs(res_gpu_vec - res_cpu_vec), na.rm = TRUE)
cat(sprintf("📊 Cross-Backend Maximum Numerical Discrepancy: %E\n", max_krig_diff))
cat(sprintf("🚀 OpenCLeaR GPGPU Acceleration Speedup: %.2fx faster than gstat!\n", time_cpu_krig / time_gpu_krig))

# 2. Build the GPU surface visualization frame
surface_gpu_df <- expand.grid(X_Metric = 1:grid_size * cell_res, Y_Metric = 1:grid_size * cell_res)
surface_gpu_df$Predicted_Z <- res_gpu_vec

plot_gpu <- ggplot(surface_gpu_df, aes(x = X_Metric, y = Y_Metric, fill = Predicted_Z)) +
  geom_raster(interpolate = TRUE) +
  scale_fill_viridis_c(option = "inferno", name = "Signal") +
  labs(title = "OpenCLeaR Output (2D GPGPU Engine)",
       subtitle = paste("Execution Time:", round(time_gpu_krig, 3), "seconds"),
       x = "Easting [m]", y = "Northing [m]") +
  theme_minimal() +
  theme(legend.position = "right")

# 3. Build the gstat CPU surface visualization frame
surface_cpu_df <- expand.grid(X_Metric = 1:grid_size * cell_res, Y_Metric = 1:grid_size * cell_res)
surface_cpu_df$Predicted_Z <- res_cpu_vec

plot_cpu <- ggplot(surface_cpu_df, aes(x = X_Metric, y = Y_Metric, fill = Predicted_Z)) +
  geom_raster(interpolate = TRUE) +
  scale_fill_viridis_c(option = "inferno", name = "Signal") +
  labs(title = "gstat Output (Optimized C/CPU Engine)",
       subtitle = paste("Execution Time:", round(time_cpu_krig, 3), "seconds"),
       x = "Easting [m]", y = "Northing [m]") +
  theme_minimal() +
  theme(legend.position = "right")

# Render both layers side-by-side for bitwise visual inspection
grid.arrange(plot_gpu, plot_cpu, ncol = 2)


## ----file_cleanup-------------------------------------------------------------
CleanCLCache()
if(file.exists("./variogram.cl")) file.remove("./variogram.cl")
if(file.exists("./variogram.cpp")) file.remove("./variogram.cpp")
if(file.exists("./kriging.cl")) file.remove("./kriging.cl")
if(file.exists("./kriging.cpp")) file.remove("./kriging.cpp")

