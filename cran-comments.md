## Checked and tested in the following environments
* macOS (Intel/radeon and Apple Silicon M-series), R 4.6.1, OpenCL
  Apple Framework (CL 1.2)
* legacy OSX (Intel Core Duo and latest mac Nvidia GPUs), R 4.x.x
  macports based installation, OpenCL Apple Framework (CL 1.2)
* Linux installations on several hardware combinations, using Nvidia
  CUDA OpenCL, intel oneapi OpenCL (CPU and GPU), AMD rocm OpenCL
  (with problems, maybe due to driver version issues on latest AMD
  Strix halo) and POCL on different CPUs.
* local Windows 11 with Nvidia CUDA and intel oneapi.
* winbuilder, no OpenCL available, nevertheless compilation succeeds
  because OpenCL ICD Loader is included as CMake external git
  project. (tinytests, vignettes and examples disabled, see below)
* GitHub Actions CI (Ubuntu 24.04.5 LTS, R 4.6.2, Intel Core CPU with
  POCL driver), headless environment, examples work but vignettes and
  tinytests are disabled, see below)

## It does not work on
* RaspberryPi OS with RustiCL, it compiles (after setting
  RUSTICL_ENABLE=v3d), loads, reports a device, but no example works.

## R CMD check results
There were no ERRORS or WARNINGS.

There were 3 NOTEs:
* 'checking installed package size ... INFO': The package includes
  compiled static/shared backend libraries for hardware management.
* 'checking pragmas in C/C++ headers': Pragmas are inherited from
  upstream OpenCL/HPP Khronos headers to suppress cross-platform
  architecture diagnostics.
* 'checking package vignettes ... NOTE': Vignettes are pre-rendered
  locally on dedicated GPU hardware and included statically to prevent
  headless server compilation timeouts.

## Special Notes for the Reviewer
This package utilizes OpenCL via JIT-compilation to run
high-performance algorithms on GPUs and CPUs allowing for easy
switches between locally available OpenCL devices.

To ensure compliance with CRAN headless policy, active hardware
testing and vignette re-generation are gracefully skipped during `R
CMD check` if no physical GPU or functional ICD loader framework is
available (e.g. on typical CRAN incoming servers), falling back to
pre-rendered artifacts and standard R checks. The only CRAN platform
which maybe could run the tinytest suite is macOS. But these tests
incorporate lots of inline c++ compiler runs which eat up a lot of
time and will run into a timeout, so tests on CRAN are disabled there
too. Please run `R CMD check` locally if OpenCL is available to see
output of the tests.
