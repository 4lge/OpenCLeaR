# We tell R that these internal JIT objects will be created on the fly!
if (getRversion() >= "2.15.1") {
  utils::globalVariables(".runif_ocl_internal")
}

##' Random number generation from a uniform distribution via OpenCL
##' 
##' @name runifOCL
##' @param n    count of random numbers to generate.
##' @param min lower boundary parameter.
##' @param max upper boundary parameter.
##' @param ... arguments passed through to \code{\link{oclFunction}} like \code{verbose} or \code{force_float}
##' @return A vector of random numbers.
##' @note This function will not necessarily increase speed of
##'   computation, it is mainly intended for checking the OpenCL runif
##'   kernel and to compare its output to R's runif function!
##' @export
runifOCL <- (function() {
  
  .runif_ocl_internal <- NULL
  function(n, min = 0, max = 1, ...) {
    if (is.null(.runif_ocl_internal)) {
      .runif_ocl_internal <<- OpenCLeaR::oclFunction(
        signature = signature(n = "integer", 
                              min = "numeric",
                              max = "numeric"),
        kernel_file = "runif.cl",
        interface_file = "runif.cpp",
        ...
        )
    }
    return(.runif_ocl_internal(as.integer(n), min, max))
  }
})()
