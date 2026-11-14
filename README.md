# 📦 OpenCLeaR: OpenCL Easy Access from R

An **R package** that simplifies writing parallel algorithms in OpenCL accessible from R.
It makes use of **CMake**, **Rcpp** and **OpenCL-Wrapper** (at least a fork of it) to ease 
platform-independent compilation and linkage to **OpenCL**. The whole package is a fork of the
**rcpp-cmake-template** package described 
[here](https://medium.com/@mail_17803/building-hardware-accelerated-r-packages-with-rcpp-and-cmake-a-practical-template-114d13b08a97)
and available at [GitHUB](https://github.com/jmaerte/cmake-rcpp-template).


---

## ✨ Highlights

- ✅ Platform-independent configuration and linkage with **CMake**,
  this is inherited from **rcpp-cmake-template** package as upstream
  dependency.
- ✅ Easy access to OpenCL via C++ interface taken from (a fork of)
  **OpenCL-Wrapper**.
- ✅ Functionality accessible via **inline** package using the provided plugin.
- ✅ Simple Rcpp integration to access the OpenCL backend.
- ✅ OpenCL kernels have access to a kernel library providing some
  alternatives to R/Rcpp functions. (currently restricted to a
  collection of r|d|p<distribution> functions like rnorm, dnorm, pnorm
  etc)

---

## 📁 Project Structure

```
OpenCLeaR
│	# Package metadata files
|	# configure and configure.win handle the installation
|
├──	src
│	│   # *.cpp define the Rcpp interface and device management functions
│	│
│	└──	backend
│		│   # A standard CMake project
|		|
|		├──	include
│		|	|	# public headers; should not include external
|		|	└──	# library headers; otherwise Rcpp needs to link too.
|		|
|		|
|		├──	src
|		|	|	# *.cpp define the actual implementation of functionality
|		|	|
|		|	└──	internal
|		|		| 	# Some internal header files that may 
|		|		└──	# include external library headers.
|		|
|		└──	lib
|			└──	# Some external library headers.
|	
├──	R
|	└──	# Caller scripts for the Rcpp functions and other R functions, especially oclFunctions.
|
├──	man
|	└──	# Documentation goes here
|
└──	inst
	| 	# The library features the possibility to load external
	└──	# resources from this folder.
        ├── kernel
        |   # OpenCL kernels for oclFunctions
        └── interface
            # Rcpp interface bodies for oclFunctions

```

📝 **Note:** Public headers (`backend/include`) define C/C++
interfaces compatible with `Rcpp`; they should not include external
library headers as `Rcpp` does not link against them. Private headers
(`backend/src/internal`) manage actual implementation details,
allowing clean abstraction.

## ⚙️ Backend with CMake

The `src/backend` directory is a standalone **CMake** project. It
builds a shared library (a static library under Windows) that is
automatically linked to the R package.

* CMake handles all platform-dependent paths and setup.

## 📂 The `inst` Folder

The `inst/` directory contains runtime resources, `.cl` kernels at
`inst/kernel` and `.cpp` interfaces at `inst/interface`. During
installation, these files from her installed at the `kernel` and
`interface` directory of the installed library and can be accessed in
R via:


```{}
system.file("kernel", package = "OpenCLeaR")
system.file("interface", package = "OpenCLeaR")
```


A simple example can be run from here:
```{}
source(paste(system.file("examples", package = "OpenCLeaR"),"idw.R",sep="/"))
```


## ⚙️ Package administration

Development task like NAMESPACE generation are automated via a Makefile:
```{}
touch NAMESPACE.in
make NAMESPACE

make RdFiles

make src/RcppExports.cpp

...
```

## 🖥️ Supported Hardware & Platform Notes

**OpenCLeaR** works across GPUs and CPUs on Linux, macOS, and Windows,
provided a functional OpenCL ICD runtime is installed.

### Tested Platforms & Runtimes

* **Linux:** Nvidia CUDA OpenCL, Intel oneAPI OpenCL (CPU & GPU), AMD
  ROCm OpenCL, and PoCL (CPU).
* **macOS / Legacy OS X:** Apple OpenCL Framework (CL 1.2) on Intel
  Macs (AMD Radeon / Intel UHD GPUs) and Apple Silicon
  M-series. *(Note: Intel CPUs on macOS >= 11 are intentionally
  filtered out because Apple's OpenCL CPU runtime returns non-portable
  CVMS references instead of standalone binaries).*
* **Windows:** Nvidia CUDA OpenCL and Intel oneAPI OpenCL. *(If no
  OpenCL runtime is present at build time, compilation still succeeds
  via the bundled Khronos OpenCL ICD Loader).*

### Known Limitations

* **Raspberry Pi OS (Mesa RustiCL):** Compiles (with
  `RUSTICL_ENABLE=v3d`), loads, and detects the device, but kernel
  execution fails due to incomplete OpenCL support in the Mesa `v3d`
  driver.

---
## 📦 Installation & System Prerequisites

Since **OpenCLeaR** compiles custom C++ extensions and links into hardware-level OpenCL drivers on the fly, a few system-level development tools and runtimes must be installed before installing the R package.

### 1. System Prerequisites

Choose your operating system to set up the build chain and OpenCL runtime:

#### 🐧 Linux (Ubuntu / Debian / Pop!_OS)
Install the essential compiler tools, **CMake**, and standard OpenCL headers:
```bash
sudo apt update
sudo apt install build-essential cmake opencl-headers
```

To enable hardware execution, set up the official package repository for your hardware vendor to pull the correct OpenCL ICD runtime:

##### ▪ NVIDIA CUDA OpenCL (GeForce, RTX, Tesla)
Do not install the stripped-down Ubuntu upstream drivers. Set up the official NVIDIA network repository to get the full deployment kit containing development headers and the runtime ICD:
```bash
# 1. Install the repository architecture requirements
sudo apt install coreutils

# 2. Fetch the official NVIDIA pinfile and repository details (example for Ubuntu 24.04)
wget https://nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/cuda-ubuntu2404.pin
sudo mv cuda-ubuntu2404.pin /etc/apt/preferences.d/cuda-repository-pin-600
sudo apt-key adv --fetch-keys https://nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/3bf863cc.pub
sudo add-apt-repository "deb https://nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/ /"

# 3. Update index and install the mandatory OpenCL runtime packages
sudo apt update
sudo apt install cuda-drivers-target-opencl opencl-icd-loaders
```

##### ▪ AMD ROCm OpenCL (Radeon GPUs, Ryzen APUs / Strix Halo)
To prevent driver signature and scheduling mismatches, hook up the official AMD package manager structures:
```bash
# 1. Download and map the AMD repository signing key
sudo mkdir -p /etc/apt/keyrings
wget -O- https://radeon.com/rocm/rocm.gpg.key | gpg --dearmor | sudo tee /etc/apt/keyrings/rocm.gpg > /dev/null

# 2. Append the target AMD repository link (example for ROCm 6.3 Stack)
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/rocm.gpg] https://radeon.com/rocm/apt/6.3 focal main" | sudo tee /etc/apt/sources.list.d/rocm.list

# 3. Apply package pinning to favor the vendor drivers over native system packages
echo -e 'Package: *\nPin: release o=://radeon.com\nPin-Priority: 600' | sudo tee /etc/apt/preferences.d/rocm-pin

# 4. Update the package index and deploy the modular compute runtime
sudo apt update
sudo apt install rocm-opencl-runtime
```

##### ▪ Intel oneAPI (Core/Xeon CPUs & Arc/Iris Graphics)
To tap into official Intel compute runtime pipelines without cloning multi-gigabyte heavy SDK stacks, set up the dedicated network repo:
```bash
# 1. Download the Intel package signing credentials
wget -O- https://intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB | gpg --dearmor | sudo tee /usr/share/keyrings/intel-sw-products.gpg > /dev/null

# 2. Mount the official target apt source list entry
echo "deb [signed-by=/usr/share/keyrings/intel-sw-products.gpg] https://intel.com/intel-mapped-path/oneapi all main" | sudo tee /etc/apt/sources.list.d/intel-oneapi.list

# 3. Synchronize package trees and mount the production-ready OpenCL runtime
sudo apt update
sudo apt install intel-oneapi-runtime-opencl
```

##### ▪ PoCL (Headless Server / Hardware-Independent CPU Fallback)
If you operate in pure sandbox virtualizations or non-accelerated CI runners without access to physical silicon, run the Portable Compute Layer vendor package:
```bash
sudo apt install pocl-opencl-icd
```

#### 🍏 macOS
You can set up the build chain either via **Homebrew** or **MacPorts**:

##### Using Homebrew:
1. Install the Xcode command-line compiler tools:
   ```bash
   xcode-select --install
   ```
2. Install **CMake**:
   ```bash
   brew install cmake
   ```

##### Using MacPorts:
1. Install the Xcode command-line compiler tools:
   ```bash
   xcode-select --install
   ```
2. Install **CMake**:
   ```bash
   sudo port install cmake
   ```
*(Note: No separate OpenCL driver installation is required. macOS automatically provides the system-wide Apple OpenCL Framework, though Intel-based CPU execution is filtered out for stability on newer OS versions)*.

#### 🪟 Windows
1. Download and install **Rtools** matching your specific R version.
2. Download and install **CMake** (ensure it is added to your system `PATH` during installation).
3. Ensure an OpenCL ICD provider is active (e.g., via NVIDIA CUDA or Intel oneAPI). If no hardware driver is present at compile time, OpenCLeaR safely falls back to compiling via its bundled static Khronos ICD loader.

Note that you can efficiently use **Scoop**, an `apt` or `port` like installer, under Windows too. 

To set up the complete build chain via **Scoop**, open PowerShell and run:
```powershell
# Install CMake
scoop install cmake

# Install Rtools (provided via the 'linwin' bucket)
scoop bucket add linwin
scoop install rtools
```

---

### 2. Installing the R Package

Once your system tools (**CMake** and compiler) are verified, open your R session and run the installation pipeline via the `remotes` package:

```r
# Install the remotes manager if not already installed
if (!requireNamespace("remotes", quietly = TRUE)) {
  install.packages("remotes")
}

# Install OpenCLeaR directly from GitHub
remotes::install_github("4lge/OpenCLeaR")
```


### 🔧 3. Linux / AMD ROCm Tuning (GPUs & APUs)

When running long-running OpenCL kernels or large memory allocations
on AMD hardware under Linux (especially recent RDNA 3 / 3.5 APUs such
as Ryzen AI / Strix Point / Strix Halo using `amdgpu` and ROCm),
default driver watchdogs and memory caps may trigger GPU ring timeouts
or allocation errors:

1. **Kernel & Firmware Version (RDNA 3.5 / Strix):** Use **Linux
   kernel >= 6.19** together with up-to-date `linux-firmware`
   (`firmware-amd-graphics`) to avoid MES scheduler / firmware lockups
   under compute load. *(On older kernels 6.12–6.18, adding
   `amdgpu.cwsr_enable=0` to the kernel command line can serve as a
   workaround).*
2. **Increase the GPU Watchdog Timeout:** Recent Linux kernels enforce
   a default `amdgpu` lockup timeout of only **2000 ms (2
   seconds)**. For compute-heavy kernels, increase this limit in
   `/etc/default/grub` (`GRUB_CMDLINE_LINUX_DEFAULT`) and run
   `update-grub`: 
```text 
amdgpu.lockup_timeout=600000
```
  *(Value is in milliseconds; `600000` = 10 minutes).*
3. **Unlock Full Unified Memory on APUs (Optional):** To allow OpenCL
   buffers to utilize more than the default shared system memory (GTT)
   limit on APUs with large RAM, set the TTM page limits (in 4 KB
   pages; e.g., `25165824` for 96 GB) in the kernel command line:
```text 
ttm.pages_limit=25165824 ttm.page_pool_size=25165824 
```
   *(Note: Modern kernels use `ttm.*` instead of the deprecated
   `amdttm.*` or `amdgpu.gttsize` parameters).*


## 🧪 Example Use Case: Inverse Distance Weighting (IDW)

The core strength of **OpenCLeaR** is `oclFunction()`. It automates
compiling an OpenCL C kernel alongside an Rcpp wrapper. It creates a
self-adapting, JIT-compiled function that manages hardware precision
shifts (FP32/FP64) internally and utilizes an optimized global RAM
cache.

### 1. The OpenCL Kernel (`inst/kernel/idw_kernel.cl`)

   This kernel executes on the GPU. The architecture-dependent
   placeholder `real` is dynamically defined as `float` or `double` at
   runtime depending on your active hardware capabilities.

```c
__kernel void idw_kernel(__global const real* x0, __global const real* y0, __global real* z0,
                         __global const real* x,  __global const real* y,  __global const real* z,
                         const int n0, const int n, const real p) {
    int i = get_global_id(0);
    if (i >= n0) return;

    real wsum = 0.0, num = 0.0;
    for (int j = 0; j < n; j++) {
        real d = sqrt((x0[i]-x[j])*(x0[i]-x[j]) + (y0[i]-y[j])*(y0[i]-y[j]));
        if (d < 1e-9) { z0[i] = z[j]; return; }
        real w = 1.0 / pow(d, p);
        wsum += w; 
        num += w * z[j];
    }
    z0[i] = num / wsum;
}
```

### 2. The Rcpp Interface (`inst/interface/idw_rcpp.cpp`)

This C++ snippet manages memory allocation on the OpenCL device. Data
is mapped efficiently using memory abstraction layers and handles data
exchange safely without DLL locks.

```cpp
NumericVector x0(r_x0);
NumericVector y0(r_y0);
NumericVector x(r_x);
NumericVector y(r_y);
NumericVector z(r_z);

int n0 = x0.size();
int n = x.size();
NumericVector r_z0(n0);

// Allocate device memory utilizing the active device pointer
Memory<real> gpu_x0(*device, n0);
Memory<real> gpu_y0(*device, n0);
Memory<real> gpu_z0(*device, n0);
Memory<real> gpu_x(*device, n);
Memory<real> gpu_y(*device, n);
Memory<real> gpu_z(*device, n);

// High-performance element-wise buffer filling
for(int i=0; i<n0; ++i) { gpu_x0[i] = x0[i]; gpu_y0[i] = y0[i]; }
for(int j=0; j<n; ++j)  { gpu_x[j] = x[j]; gpu_y[j] = y[j]; gpu_z[j] = z[j]; }

// Push buffers to the OpenCL device
gpu_x0.write_to_device(); gpu_y0.write_to_device();
gpu_x.write_to_device();  gpu_y.write_to_device(); gpu_z.write_to_device();

// Enqueue and execute the JIT-compiled kernel
Kernel k(*device, n0, "idw_kernel", gpu_x0, gpu_y0, gpu_z0, gpu_x, gpu_y, gpu_z, n0, n, as<real>(p));
k.run();

// Read result matrix back to host RAM
gpu_z0.read_from_device();
for(int i=0; i<n0; ++i) r_z0[i] = gpu_z0[i];

return r_z0;
```

### 3. Generating and Executing the Cached R Interface

In R, you stitch both files together using `oclFunction()`. The call
pattern utilizes an **Evaluate-in-Place** pipeline via a double
closure `()(...)`:

```R
library(OpenCLeaR)

# 1. Activate your target OpenCL backend hardware (e.g., GPU)
ActivateDevice(0)

# 2. Construct the hardware-adaptive JIT wrapper function
idw_gpu <- oclFunction(
    signature = signature(r_x0="numeric", r_y0="numeric", r_x="numeric",
                          r_y="numeric", r_z="numeric", p="numeric"),
    kernel_file    = "idw_kernel.cl",
    interface_file = "idw_rcpp.cpp"
)

# 3. Execute the function. Sub-sequent hardware switches are handled automatically.
result <- idw_gpu(target_x, target_y, source_x, source_y, source_z, p = 2.0)
```

### 4. Encapsulate the function in a R wrapper ready to be used in your library

After development of your function you may use this cached IIFE
function (Immediately Invoked Function Expression):

```R
if (getRversion() >= "2.15.1") {
    utils::globalVariables(".idw_ocl_internal")
}

##' Inverse Distance Weighting (IDW) parallelized via OpenCL
##'
##' @name idwOCL
##' @param x0    vector of target x-coordinates.
##' @param y0    vector of target y-coordinates.
##' @param x     vector of known source x-coordinates.
##' @param y     vector of known source y-coordinates.
##' @param z     vector of known source values.
##' @param p     power parameter (distance weight).
##' @param ...   arguments passed through to \code{\link{oclFunction}}
##' @return A numeric vector of interpolated values.
##' @export
idwOCL <- (function() {
  .idw_ocl_internal <- NULL
  function(x0, y0, x, y, z, p = 2.0, ...) {
    if (is.null(.idw_ocl_internal)) {
      .idw_ocl_internal <<- OpenCLeaR::oclFunction(
        signature = methods::signature(
          r_x0 = "numeric", 
          r_y0 = "numeric", 
          r_x  = "numeric", 
          r_y  = "numeric", 
          r_z  = "numeric", 
          p    = "numeric"
        ),
        kernel_file = "idw_kernel.cl", 
        interface_file = "idw_rcpp.cpp", 
        ...
      )
    }
    return(.idw_ocl_internal(x0, y0, x, y, z, p))
  }
})()
```

## 📚 Resources

- [CMake Documentation](https://cmake.org/documentation/)
- [Rcpp Package](https://cran.r-project.org/package=Rcpp)
- [Writing R Extensions](https://cran.r-project.org/doc/manuals/r-release/R-exts.html)

## 🛠️ Getting Started

Look into the provided vignettes ...

## 🧑‍💻 Contributions

Contributions, suggestions, and issues are welcome! Feel free to open a pull request or issue.

## 📄 License

MIT License. See `LICENSE` and `LICENSE.note` for details.


