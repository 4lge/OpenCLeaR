# OpenCLeaR 0.7.3

* **Initial CRAN Release Candidate:** Full integration of high-performance spatial estimation and GPGPU validation pipelines.
* **Native 2D Ordinary Kriging Example:** Implemented a hardware-parallelized 2D Kriging architecture resolving thousands of spatial equations concurrently on the GPU.
* **Lin-Alg Routines Testing:** Upgraded the 2D Kriging example grid to directly utilize the core Generalized Least Squares (`wls_gls_fit`) and Cholesky (`core_cholesky`) frameworks from the internal `libkernel.cl` library, serving as a robust end-to-end mathematical validation suite.
* **Just-In-Time (JIT) Adaptability:** Deployed native JIT compilation mechanics with automated host-device precision filtering (FP32/FP64 detection).
* **Persistent Binary Caching:** Integrated scoped closure patterns (IIFE) to cache compiled OpenCL binaries natively within the active R session, eliminating runtime compilation overhead during iterative operations.
* **Expanded Vignette Portfolio:** Added pre-rendered vignettes featuring comprehensive, real-world geostatistical benchmarks against the industry-standard `gstat` package alongside parallel MCMC sampling architectures.
* **CRAN Isolation Shields:** Included a hardware-agnostic diagnostic fall-through inside the `tinytest` suite, ensuring graceful degradation on CRAN check servers lacking physical GPU runtimes.

