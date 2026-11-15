## 🚀 OpenCLeaR Advanced Roadmap & Architectural Evolution

### 🗺️ Phase 1: Core Framework & Runtime Compilation (Completed)
- [x] Create a robust template OpenCL kernel system for heavy parallel architectures (e.g., MH Sampling / Geostatistics).
- [x] Build concrete OpenCL implementations and mathematical baselines by providing native distributions inside `libkernel.cl`.
- [x] Architect the dynamic `oclFunction` JIT pipeline to replace rigid `inline::cxxfunction` concepts.
  - [x] Dynamically load and compile raw OpenCL source code strings on the fly.
  - [x] Instatiate unified host/device memory streams via high-level `Memory<real>` wrapper objects.
  - [x] Launch optimized execution grids and safely return matrices directly to the active R session.
- [x] Establish a runtime header infrastructure by copying backend headers via `inst/include` to make them globally accessible during R runtime JIT tasks.
- [x] Secure C++20 compliance for modern toolchains (GCC 14) via explicit `[this]` lambda captures inside `opencl.hpp`.

### 📊 Phase 2: Mathematical Rigor & Validation (Completed)
- [x] Implement a true 2D Ordinary Kriging engine resolving thousands of spatial equations concurrently on the GPU.
- [x] Resolve severe `gstat` CPU stalls inside validation benchmarks using spatial neighborhood radius and `nmax=50` filters.
- [x] Establish a rigorous end-to-end integration test for the custom linear algebra library (`wls_gls_fit`, `core_cholesky`) within the geostatistics vignette.
- [x] Deploy an optimized insertion-sort array routing layer into GPU threads, enabling radius-bounded, capped neighborhood tracking (`MAX_NEIGHBORS`) for highly accelerated branch-skipping.

### 📝 Task 1: Technical Whitepaper & Journal Manuscript (Next Step)
- [ ] Document the conceptual architecture of the R -> Rcpp -> OpenCL Driver JIT pipeline.
- [ ] Detail the internal mechanics, memory marshalling, and caching layout backing the `oclFunction` environment.
- [ ] Validate numerical stability and baseline performance using a parallel IDW/Kriging configuration.

### 🧊 Task 2: 3D Voxel Diffusion Prototype (Future Extension)
- [ ] Implement a 3D execution grid kernel mapping three spatial index planes (`get_global_id` 0, 1, 2).
- [ ] Setup 6-point spatial stencil masks for local neighbor voxel communication (Top, Bottom, N, S, E, W).
- [ ] Deploy VRAM double-buffering ping-pong schemas for safe iterative time-steps without race conditions.
- [ ] Lay the foundation for complex 3D DEM air pollutant transport models inside meteorological wind fields.

