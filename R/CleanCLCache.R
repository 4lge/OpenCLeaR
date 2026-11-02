##' @title Clear Temporary OpenCL Binary Caches
##'
##' @description
##' Purges the temporary \code{.cl_cache} directories generated during 
##' JIT compilation steps to leave a clean workspace.
##' 
##' @return Invisibly returns \code{TRUE} on success.
##'
##' @examples
##' # This example block runs last in R CMD check due to the zz_ file alias!
##' message(" [OpenCLeaR] Performing JIT cache cleanup...")
##' CleanCLCache()
##' 
##' @name zz_CleanCLCache
##' @export
CleanCLCache <- function() {
    targets <- c("./.cl_cache") # , "../.cl_cache", "../../.cl_cache")
    for (target in targets) {
        if (dir.exists(target)) {
            unlink(target, recursive = TRUE, force = TRUE)
        }
    }
    invisible(TRUE)
}

