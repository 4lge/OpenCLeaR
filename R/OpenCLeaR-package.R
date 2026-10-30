##' @import Rcpp
##' @importFrom inline cxxfunction
##' @importFrom Rcpp evalCpp sourceCpp
##' @importFrom methods signature
##' @importFrom utils getFromNamespace
##' @useDynLib OpenCLeaR, .registration = TRUE


"_PACKAGE"

## This collects device state variables as well as cached JIT
## compiled functions
.OpenCLeaR_Env <- new.env(parent = emptyenv())


## onLoad function:
.onLoad <- function(libname, pkgname) {
    ## =========================================================================
    ##  Dynamic Linker preload switch for Linux and macOS
    ## =========================================================================
    if (.Platform$OS.type == "unix") {
        is_mac <- grepl("darwin", R.version$os)
        ext    <- if (is_mac) ".dylib" else ".so"

        backend_file <- paste0("libBACKEND", ext)
        backend_so   <- system.file("libs", backend_file, package = pkgname)

        ## Preloads the symbols of libBACKEND globally so that OpenCLeaR.so can find them
        if (file.exists(backend_so)) {
            dyn.load(backend_so, local = FALSE, now = TRUE)
        }
    } ## not needed on Windows as there BACKEND.a is a static library

    if (.Platform$OS.type == "windows") {
        ## We completely disable the Nvidia hard drive cache!
        ## Possible source of trouble on Windows!
        Sys.setenv(CUDA_CACHE_DISABLE = "1")
        ## Prevent OpenMP background threads from blocking
        ## in the R loader on Windows
        Sys.setenv(OMP_NUM_THREADS = "1")
    }
    ## Determine the real, absolute installation path of the kernels in the package!
    kernel_dir <- system.file("kernel", package = pkgname, lib.loc = libname)
    if (kernel_dir == "") {
        ## Fallback for a local development environment
        kernel_dir <- normalizePath("./kernel", mustWork = FALSE)
    }
    .OpenCLeaR_Env$kernel_path <- kernel_dir

    ## Registers all three plugins when loading the package
    inline::registerPlugin("OpenCLeaR", inlineCxxPlugin)
    inline::registerPlugin("OpenCLeaRFloat", inlineCxxPluginFloat)
    inline::registerPlugin("OpenCLeaRDouble", inlineCxxPluginDouble)

    ## We set these flags to FALSE by default initially.
    ## They only become TRUE if the initialization works later.
    options(OpenCLeaR.initialized = FALSE)
    options(OpenCLeaR.has_fp64 = FALSE)
}


## 2. ONATTACH: The perfect place for fail-safe hardware autostart!
.onAttach <- function(libname, pkgname) {
    ## Show this notice ONLY if NO device could be bound automatically!
    if (!isTRUE(getOption("OpenCLeaR.initialized"))) {
        kernel_dir <- .OpenCLeaR_Env$kernel_path
        packageStartupMessage(
            "\n==========================================================================\n",
            "  (Kernel path: ", kernel_dir, ").\n",
            "  [OpenCLeaR] OpenCL environment loaded but NOT yet bound to hardware!\n",
            "  PLEASE RUN: GetDevicelist() and use ActivateDevice(<index>) to select\n",
            "  and initialize your GPU/CPU OpenCL device.\n",
            "=========================================================================="
        )
    }
}


##' Activate OpenCL devices
##'
##' Activates an OpenCL device in a fail-safe and block-free manner.
##' @param idx Optional integer index of the device (default: 0)
##' @export
ActivateDevice <- function(idx = 0) {
    idx_int <- as.integer(idx)
    env <- .OpenCLeaR_Env

    ## =========================================================================
    ## The Windows PATH: use device pointer tunneled through
    ## =========================================================================
    if (.Platform$OS.type == "windows") {
        devs <- tryCatch({ GetDeviceList() }, error = function(e) NULL)
        if (is.null(devs) || !is.data.frame(devs)) {
            stop(" [OpenCLeaR]  OpenCL hardware list could not be read!")
        }

        if (idx_int < 0 || idx_int >= nrow(devs)) {
            warning(" [OpenCLeaR] invalid index: ", idx_int)
            return(invisible(FALSE))
        }

        target_platform <- as.integer(devs[devs$Index == idx_int, "Platform_ID"])
        target_device   <- as.integer(devs[devs$Index == idx_int, "Device_ID"])

        cat(" [OpenCLeaR Windows] using pointer-bridge (platform:", target_platform, ", device:", target_device, ")\n")
        
        ## Creates the transient device object in RAM without singleton lock:
        env$active_device_ptr <- .create_transient_device_cpp(idx_int, target_platform, target_device, env$kernel_path)

        options("OpenCLeaR.initialized" = TRUE)
        options("OpenCLeaR.active_device" = idx_int)
        options("OpenCLeaR.has_fp64" = as.logical(devs[devs$Index == idx_int, "FP64_Capable"]))

        return(TRUE)
    }

    ## =========================================================================
    ##  LINUX / MAC Path: use OpenPhysx original device creation
    ## =========================================================================
    if (!isTRUE(getOption("OpenCLeaR.initialized"))) {
        initialized_now <- EnsureOpenclInitialized()
        if (!initialized_now) {
            stop(" [OpenCLeaR] OpenCL subsystem could not be initialised!")
        }
    }

    devs <- tryCatch({ GetDeviceList() }, error = function(e) NULL)
    if (is.null(devs) || !is.data.frame(devs)) {
        stop(" [OpenCLeaR] OpenCL hardware list could not be read!")
    }

    if (idx_int < 0 || idx_int >= nrow(devs)) {
        warning(" [OpenCLeaR] invalid index: ", idx_int)
        return(invisible(FALSE))
    }

    target_platform <- as.integer(devs[devs$Index == idx_int, "Platform_ID"])
    target_device   <- as.integer(devs[devs$Index == idx_int, "Device_ID"])

    success <- tryCatch({
        ActivateDeviceWithIndex_Native(idx_int)
        TRUE
    }, error = function(e) FALSE)

    if (success) {
        options("OpenCLeaR.initialized" = TRUE)
        options("OpenCLeaR.active_device" = idx_int)
        options("OpenCLeaR.has_fp64" = as.logical(devs[devs$Index == idx_int, "FP64_Capable"]))
        return(TRUE)
    } else {
        options("OpenCLeaR.initialized" = FALSE)
        options("OpenCLeaR.has_fp64" = FALSE)
        return(FALSE)
    }
}

##' Initialzes OpenCL driver.
##'
##' It tries also to silently fail on installations without any OpenCL available.
##' This is needed to be built e.g. on CRANs win-builder platform or other CRAN
##' package checkers.
##' @export
EnsureOpenclInitialized <- function() {
    ## return if already initialized
    if (isTRUE(getOption("OpenCLeaR.initialized"))) return(TRUE)

    ## in case that during R CMD check bin/ocl_compiler lost its execution rights:
    if (.Platform$OS.type == "unix") {
        compiler_binary <- file.path(system.file("bin", package = "OpenCLeaR"), "ocl_compiler")
        if (file.exists(compiler_binary)) {
            Sys.chmod(compiler_binary, mode = "0755", use_umask = FALSE)
        }
    }

    ## under Windows check registry for registered OpenCL providers
    if (.Platform$OS.type == "windows") {
        has_vendors <- tryCatch({
            ## Scans the official Khronos registry path for installed drivers
            vendors <- utils::readRegistry("SOFTWARE\\Khronos\\OpenCL\\Vendors", "HLM")
            if(GetKernelsPath() == "" || nchar(GetKernelsPath()) == 0){
                kernelPath <- system.file("kernel", package = "OpenCLeaR") 
                SetKernelsPath(kernelPath) 
            }
            length(vendors) > 0
        }, error = function(e) FALSE)

        if (!has_vendors) {
            ## No drivers installed! Immediate termination without DLL call
            options(OpenCLeaR.initialized = FALSE)
            return(FALSE)
        }
    } else {
        if(GetKernelsPath() == "" || nchar(GetKernelsPath()) == 0){
            kernelPath <- system.file("kernel", package = "OpenCLeaR")
            SetKernelsPath(kernelPath) 
        }
    }

    ## Try to activate the hardware
    status <- tryCatch({
        ## STEP 1: Scan the hardware absolutely securely and block-free (setupDevices)
        InitCL()

        ## STEP 2: CHECK NOW: Is it a real device or just the dummy object?
        if (IsOpenCLReady()) {
            options(OpenCLeaR.initialized = TRUE)
            TRUE
        } else {
            options(OpenCLeaR.initialized = FALSE)
            FALSE
        }
    }, error = function(e) {
        options(OpenCLeaR.initialized = FALSE)
        FALSE
    })

    return(status)
}

##' Gets the kernel path currently set in the C++ backend
##' @return A string with the path
##' @export
GetKernelsPath <- function() {
    return(.GetKernelsPath_cpp())
}

##' Activates an OpenCL device in an absolutely fail-safe manner
##' @param idx The index of the device to activate (default: 0)
##' @export
ActivateDeviceWithIndex <- function(idx) {
    ActivateDevice(idx)
}
