# We tell R that these internal JIT objects will be created on the fly!
if (getRversion() >= "2.15.1") {
  utils::globalVariables(".rpois_ocl_internal")
}
##' Random number generation from a poisson distribution via OpenCL
##' 
##' @name rpoisOCL
##' @param n count of random numbers to generate.
##' @param lambda vector of (non-negative) means.
##' @param ... arguments passed through to \code{\link{oclFunction}}
##' @return A vector of random numbers.
##' @note This function will not necessarily increase speed of computation.
##' @export
rpoisOCL <- (function() {
  
    .rpois_ocl_internal <- NULL  
    function(n, lambda, ...) {   
    if (is.null(.rpois_ocl_internal)) {
        .rpois_ocl_internal <<- OpenCLeaR::oclFunction(
          signature      = methods::signature(n = "integer", lambda = "numeric"),
            kernel_file    = "rpois.cl",
            interface_file = "rpois.cpp",
            ...
       )
    }
        return(.rpois_ocl_internal(as.integer(n), lambda))
    }
})()
