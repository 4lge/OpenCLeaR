# OpenCLeaR 0.7.3

* Initial CRAN submission.
* Integrated cross-platform OpenCL GPGPU acceleration using Rcpp and CMake.
* Implemented Just-In-Time (JIT) compilation for adaptive architecture support (FP32/FP64 detection mechanics).
* Added automated evaluation-in-place function caching using an Immediately Invoked Function Expression (IIFE) closure pattern to reduce runtime compilation overhead.
* Included comprehensive test suite powered by `tinytest` with native hardware detection. Note that these tests will not run on CRAN package testing servers due to lack of OpenCL resources. 
* Added pre-rendered vignettes demonstrating high-performance MCMC sampling and Inverse Distance Weighting (IDW).

