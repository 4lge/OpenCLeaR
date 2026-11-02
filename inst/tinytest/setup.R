## ==============================================================================
## BEFORE ALL TESTS: initialized in advance
## ==============================================================================

library(OpenCLeaR)

if (!EnsureOpenclInitialized()) {
    tinytest::exit_file("OpenCL infrastructure not available on this host")
} else {
    if (identical(Sys.getenv("_R_CHECK_CRAN_INCOMING_"), "true")) {
       tinytest::exit_file("Skipping time-intensive C++ OpenCL tests during CRAN incoming checks.")
    }
    ActivateDevice(0)
}

inline::registerPlugin("inlineCxxPlugin", OpenCLeaR::inlineCxxPlugin())
inline::registerPlugin("inlineCxxPluginFloat", OpenCLeaR::inlineCxxPluginFloat())
inline::registerPlugin("inlineCxxPluginDouble", OpenCLeaR::inlineCxxPluginDouble())

## ==============================================================================
## AFTER ALL TESTS: Cleanup of the .cl_cache directory
## ==============================================================================

## We register a finalizer to the current environment.
## This is guaranteed to be executed as soon as tinytest leaves the test environment.
reg.finalizer(environment(), function(e) {

    ## Determine the path to the .cl_cache in the temporary check directory
    ## Since devtools::check() sets the working directory to the test directory:
    cache_dir <- "./.cl_cache"

    if (dir.exists(cache_dir)) {
        message("\n [OpenCLeaR Clean] Remove .cl_cache from test directory...")

        ## Deletes the folder recursively and force delete (force = TRUE)
        unlink(cache_dir, recursive = TRUE, force = TRUE)

        if (!dir.exists(cache_dir)) {
            message(" [OpenCLeaR Clean].cl_cache cleaned successfully.")
        } else {
            warning(" [OpenCLeaR Clean].cl_cache could not be completely cleared.")
        }
    }
}, onexit = TRUE)
