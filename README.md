# 📦 OpenCLeaR: OpenCL Easy Access from R

A **R package** that simplifies writing parallel algorithms in OpenCL accessible from R.
It makes use of **CMake**, **Rcpp** and **OpenCL-Wrapper** (at least a fork of it) to ease 
platform-independent compilation and linkage to **OpenCL**. The whole package is based on a
**rccp-cmake-template** package described (here)[https://medium.com/@mail_17803/building-hardware-accelerated-r-packages-with-rcpp-and-cmake-a-practical-template-114d13b08a97]
and available at (GitHUB)[https://github.com/jmaerte/cmake-rcpp-template].


---

## ✨ Highlights

- ✅ Platform-independent configuration and linkage with **CMake**, this is inherited from **rcpp-cmake-template** package as upstream dependdency. 
- ✅ Easy access tk OpenCL vie C++ interface taken from (a fork of) **OpenCL-Wrapper**.
- ✅ Functionality accessible via **inline** package using the provided plugin.
- ✅ Simple Rcpp integration to access the OpenCL backend.
- ✅ OpenCL kernels have access to a kernel library providing some alternatives to R/Rcpp functions. (currently restricted to a collection of r|d|p<dsitrib> functions like rnorm, dnorm, pnorm etc)

---

## 📁 Project Structure

```
cmake-rcpp-template
│	# Package metadata files
|	# configure and configure.win handle the installation
|
├──	src
│	│   # *.cpp define the Rcpp wrapper functions
│	│
│	└──	backend
│		│   # A standard CMake project
|		|
|		├──	include
│		|	|	# public headers; should not include external
|		|	└──	# library headers; otherwise Rcpp needs to link too.
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
|	└──	# Caller scripts for the Rcpp functions and other R functions
|
├──	man
|	└──	# Documentation goes here
|
└──	inst
	| 	# The library features the possibility to load external
	└──	# resources from this folder.
```

📝 **Note:** Public headers (`backend/include`) define C/C++ interfaces compatible with `Rcpp`; they should not include external library headers as `Rcpp` does not link against them. Private headers (`backend/src/internal`) manage actual implementation details, allowing clean abstraction.

## ⚙️ Backend with CMake
The `src/backend` directory is a standalone **CMake** project. It builds a shared library that is automatically linked to the R package.

* Extend linkage easily in `CMakeLists.txt` for OpenCL, OpenGL, etc.

* CMake handles all platform-dependent paths and setup.

## 📂 The `inst` Folder

The `inst/` directory contains runtime resources (e.g., `.cl` kernels). During installation, files from `src/backend/kernels` are copied into `inst/kernels` using the `configure` and `configure.win` scripts.

``````r
# Accessed in R via:
system.file("kernels", package = "CMakeRcppTemplate")
``````


An **inline** call could look like this:
`````
source(paste(system.file("inst/examples", package = "OpenCLeaR"),"rnormCLinline.R",sep="/"))
`````

These paths are injected into the shared library at runtime using the `.onLoad` hook (see `R/CMakeRcppTemplate.R`), enabling dynamic loading of external resources like OpenCL kernels or OpenGL shaders.

## 🔗 Rcpp Integration

This template uses **manual `SEXP` wrappers** for each Rcpp function (instead of `[[Rcpp::export]]`) to avoid platform-specific issues:

> On some systems, `enterRNGScope` errors to be undefined in `RcppExports.o` even though it was not used in `RcppExports.cpp` when using auto-generated bindings via `compileAttributes()`.

However, for simplicity, you *may* choose to use `[[Rcpp::export]]` if you're willing to trade off some portability.

📌 **Important**:

- Add `import(Rcpp)` to the top of your `NAMESPACE` file to avoid errors like:

  ```text
  Rcpp_precious_remove not provided by package Rcpp.
  ```

- Manually written R wrappers for `SEXP` functions should defensively check input types, since auto-type checks are not generated without `[[Rcpp::export]]`.

## 📤 Exports

Your package may export:

- `SEXP`-wrapper functions via `Rcpp`
- High-level R functions that internally call C/C++ via `Rcpp`
- High-level R functions that are independent of the C/C++ backend

## 🧪 Example Use Case

This template includes an example GPU-based distance matrix computation via **OpenCL**. No changes are required to Rcpp code when adding new backend libraries — just update the CMake configuration.

## 📚 Resources

- [CMake Documentation](https://cmake.org/documentation/)
- [Rcpp Package](https://cran.r-project.org/package=Rcpp)
- [Writing R Extensions](https://cran.r-project.org/doc/manuals/r-release/R-exts.html)

## 🛠️ Getting Started

1. Clone this repository (use `--recursive` option in order to get the OpenCL headers aswell!)
2. Modify the `src/backend/` CMake code and `src/*.cpp` `Rcpp`- and `SEXP`-bindings
3. Add new R functions in the `R/` directory calling your `SEXP`-binding functions
4. Document functions via `Rmarkdown` in `man`
5. Adjust the section `copying kernels` in `configure` and `configure.win` according to your external resources.
6. Build and install using `devtools::install()` or `R CMD INSTALL`

## 🧑‍💻 Contributions

Contributions, suggestions, and issues are welcome! Feel free to open a pull request or issue.

## 📄 License

MIT License. See `LICENSE` for details.

> ⚠️ Author's Note: This project was created while I was affiliated with **IAP-GmbH Intelligent Analytics Projects**.

