# 📦 OpenCLeaR: OpenCL Easy Access from R

A **R package** that simplifies writing parallel algorithms in OpenCL accessible from R.
It makes use of **CMake**, **Rcpp** and **OpenCL-Wrapper** (at least a fork of it) to ease 
platform-independent compilation and linkage to **OpenCL**. The whole package is a fork of the
**rccp-cmake-template** package described 
(here)[https://medium.com/@mail_17803/building-hardware-accelerated-r-packages-with-rcpp-and-cmake-a-practical-template-114d13b08a97]
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
|	└──	# Caller scripts for the Rcpp functions and other R functions
|
├──	man
|	└──	# Documentation goes here
|
└──	inst
	| 	# The library features the possibility to load external
	└──	# resources from this folder.
			├──	kernel
    	| 	# OpenCL kernels for oclFunctions
      └── interface
    	  	# Rcpp interface bodies for oclFunctions

```

📝 **Note:** Public headers (`backend/include`) define C/C++ interfaces compatible with `Rcpp`; they should not include external library headers as `Rcpp` does not link against them. Private headers (`backend/src/internal`) manage actual implementation details, allowing clean abstraction.

## ⚙️ Backend with CMake
The `src/backend` directory is a standalone **CMake** project. It builds a shared library that is automatically linked to the R package.

* Extend linkage easily in `CMakeLists.txt` for OpenCL, OpenGL, etc.

* CMake handles all platform-dependent paths and setup.

## 📂 The `inst` Folder

The `inst/` directory contains runtime resources (e.g., `.cl` kernels and `.cpp` interfaces). During installation, files from `src/backend/kernels` are copied into `inst/kernels` using the `configure` and `configure.win` scripts.

``````r
# Accessed in R via:
system.file("kernels", package = "OpenCLeaR")
``````


An **inline** call could look like this:
`````
source(paste(system.file("inst/examples", package = "OpenCLeaR"),"rnormCLinline.R",sep="/"))
`````



NAMESPACE genration is automated vie Makefile:
```{}
touch NAMESPACE.in
make NAMESPACE
```

## 🧪 Example Use Case

TBW

## 📚 Resources

- [CMake Documentation](https://cmake.org/documentation/)
- [Rcpp Package](https://cran.r-project.org/package=Rcpp)
- [Writing R Extensions](https://cran.r-project.org/doc/manuals/r-release/R-exts.html)

## 🛠️ Getting Started

TBW

## 🧑‍💻 Contributions

Contributions, suggestions, and issues are welcome! Feel free to open a pull request or issue.

## 📄 License

MIT License. See `LICENSE` for details.


