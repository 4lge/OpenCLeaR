## Checked and tested in the following environments

* macOS (Intel with AMD Radeon/Intel UHD GPUs and Apple Silicon M-series),
  R 4.6.1, Apple OpenCL Framework (CL 1.2). Note: Intel CPUs on macOS >= 11
  are intentionally filtered out because Apple's OpenCL CPU runtime returns
  non-portable CVMS references instead of standalone binaries.
* Legacy OS X (Intel Core Duo and legacy Mac Radeon and Nvidia GPUs), 
  R 4.x.x MacPorts-based installation, Apple OpenCL Framework (CL 1.2).
* Linux installations on several hardware combinations, using Nvidia
  CUDA OpenCL, Intel oneAPI OpenCL (CPU and GPU), AMD ROCm OpenCL
  (note: experimental/recent APUs such as AMD Strix Halo may exhibit
  upstream driver issues), and PoCL on various CPUs.
* Local Windows 11 with Nvidia CUDA and Intel oneAPI.
* Win-builder: No OpenCL runtime available; compilation succeeds because
  the Khronos OpenCL ICD Loader is built via CMake. Hardware-dependent
  tinytests, vignettes, and examples are gracefully skipped (see below).
* GitHub Actions CI (Ubuntu 24.04.5 LTS, R 4.6.2, Intel Core CPU with
  PoCL driver), headless environment; examples run successfully, while
  vignettes and tinytests are skipped due to runtime limits (see below).

## Known unsupported platforms

* Raspberry Pi OS with RustiCL: Compiles (after setting
  `RUSTICL_ENABLE=v3d`), loads, and detects the device, but kernel
  execution fails due to incomplete OpenCL support in the Mesa v3d driver.

## R CMD check results

There were no ERRORs or WARNINGs.

There were some NOTEs, depending on the R version (R-oldrelease,
R-release, or R-devel):

* `Possibly misspelled words in DESCRIPTION`: False positives for
  technical terms such as `OpenCL`.
* `checking installed package size ... INFO`: The package includes
  compiled static/shared backend libraries and standalone compiler tools
  required for OpenCL hardware management.
* `checking pragmas in C/C++ headers`: Pragmas are inherited from
  upstream Khronos OpenCL/HPP headers to suppress cross-platform
  compiler diagnostics.
* `Found the following (possibly) invalid URLs`: The flagged URLs in
  `README.md` are valid and accessible in standard browsers; the NOTE
  is likely caused by bot/User-Agent restrictions on the target servers.

## Special Notes for the Reviewer

This package utilizes OpenCL via JIT compilation to run high-performance
algorithms on GPUs and CPUs, allowing seamless switching between locally
available OpenCL devices. This is achieved through a C++ framework that
abstracts low-level OpenCL C/C++ API calls into three core classes
(`Device`, `Memory`, and `Kernel`) alongside a convenient `oclFunction`
interface combining OpenCL kernels with Rcpp wrappers. The implementation
automatically adapts to the floating-point capabilities (`fp64`/`fp32`) of
the active OpenCL device via runtime compilation and C++ templating around
an abstract `real` type. The package also provides a library of OpenCL-C
kernel functions mimicking base R functions (e.g., `runif`, `dnorm`,
`qbinom`), which are verified by the included `tinytest` suite.

To comply with CRAN policies for headless build servers, active hardware
tests and vignette re-generation are gracefully skipped during
`R CMD check` when no physical GPU or functional OpenCL ICD runtime is
available, falling back to pre-rendered artifacts.

While CRAN's macOS check servers may provide an OpenCL-capable GPU,
running the full `tinytest` suite triggers numerous inline C++ and OpenCL
compilations requiring approximately 30 minutes, which would exceed
CRAN's check time limits. Therefore, the `tinytest` suite is skipped on
CRAN check servers by default (controlled via environment checks) and
intended to be run locally.

Please feel free to run the full test suite locally if OpenCL hardware
is available.

