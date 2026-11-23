## 🚀 OpenCLeaR Advanced Roadmap & Architectural Evolution

### 🗺️ Phase 1: Core Framework & Runtime Compilation (Completed)
- [x] Create a robust template OpenCL kernel system for heavy parallel architectures (e.g., MCMC Sampling).
- [x] Build concrete OpenCL implementations and mathematical baselines by providing native distributions inside `libkernel.cl`.
- [x] Architect the dynamic `oclFunction` JIT pipeline to replace rigid `inline::cxxfunction` concepts.
  - [x] Dynamically load and compile raw OpenCL source code strings on the fly.
  - [x] Instantiate unified host/device memory streams via high-level `Memory<real>` wrapper objects.
  - [x] Launch optimized execution grids and safely return vectors/matrices directly to the active R session.
- [x] Establish a runtime header infrastructure by copying backend headers via `inst/include` to make them globally accessible during R runtime JIT tasks.
- [x] Secure C++20 compliance for modern toolchains (GCC >= 14) via explicit `[this]` lambda init-captures inside `opencl.hpp`.

### 📊 Phase 2: Mathematical Rigor & Validation (Completed)
- [x] Implement a true 2D Ordinary Kriging engine resolving thousands of spatial equations concurrently on the GPU using the internal linear algebra library (`wls_gls_fit`, `core_cholesky`).
- [x] Resolve severe `gstat` CPU stalls inside validation benchmarks using spatial neighborhood radius and `nmax = 50L` filters.
- [x] Establish a rigorous end-to-end integration test for the custom linear algebra library within the geostatistics vignette (`vignettes/OpenCLeaR_Geostatistics_Vignette.Rmd`).
- [x] Deploy an optimized insertion-sort array routing layer into GPU threads, enabling radius-bounded, capped neighborhood tracking (`MAX_NEIGHBORS = 50`) for highly accelerated branch-skipping.

### 📝 Task 1: Technical Whitepaper & Journal Manuscript (Next Step)
- [ ] Document the conceptual architecture of the R -> Rcpp -> OpenCL Driver JIT pipeline.
- [ ] Detail the internal mechanics, memory marshalling, and caching layout backing the `oclFunction` environment.
- [ ] Validate numerical stability and baseline performance using a parallel IDW / Kriging configuration.

### 🧊 Task 2: 3D Voxel Diffusion Prototype (Future Extension)
- [ ] Implement a 3D execution grid kernel mapping three spatial index planes (`get_global_id` 0, 1, 2).
- [ ] Setup 6-point spatial stencil masks for local neighbor voxel communication (Top, Bottom, N, S, E, W).
- [ ] Deploy VRAM double-buffering ping-pong schemas for safe iterative time-steps without race conditions.
- [ ] Lay the foundation for complex 3D DEM air pollutant transport models inside meteorological wind fields.

### 🎲 Phase 3: Cross-Platform RNG Abstraction & Modular Kernel Libraries (In Progress)
- [x] Decouple OpenCL distribution samplers in `libkernel.cl` from underlying PRNG state via `INIT_RNG`, `RNG_PROTOTYPE`, `RNG_ARGS`, and `RNG_01_ARGS` macros.
- [x] Implement lightweight 16-byte `Xorshift128` backend (`-D USE_FAST_RNG`) alongside default 2.5 KB `Mersenne-Twister` (`MT19937`) to comply with Apple Silicon Metal per-thread private memory limits.
- [x] Forward compiler build options (`-o "-D USE_FAST_RNG"`) through `Device::set_build_options()` into `ocl_compiler` and isolate `.bin` cache entries via `_xor` / `_mt` suffixes.
- [x] Add runtime `RNGkind` switching via `.extract_rng_kind(...)` and RNG-aware `.OpenCLeaR_Env` cache keys in `oclFunction()` and `rnormOCL()`.
- [ ] Persist `last_rng_kind <<- RNGkind` in the recompile branch of `oclFunction()` (`R/inline.R`) and roll out `.extract_rng_kind(...)` across all remaining `r*OCL()` wrappers (`runifOCL`, `rtOCL`, `rgammaOCL`, `rpoisOCL`, `rmvnormOCL`, etc.).
- [ ] Support ordered vector notation for `math_lib = c("libkernel.cl", "./mylib.cl", "dependentpkg::otherlib.cl")` in `inlineCL()` / `oclFunction()`, resolving package kernels, local files, and external package headers in sequence with mtime-aware cache invalidation.
- [ ] Optional: Add standalone R `nmath` PRNG backend (`RNGkind = "nmath"`) in `libkernel.cl`.
