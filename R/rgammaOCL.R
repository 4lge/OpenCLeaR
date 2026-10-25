if (getRversion() >= "2.15.1") {
    utils::globalVariables(".rgamma_ocl_internal")
}
##' Random number generation from a gamma distribution via OpenCL
##'
##' @name rgammaOCL
##' @param n      count of random numbers to generate.
##' @param shape  shape parameter (must be positive).
##' @param rate   inverse scale parameter (must be positive).
##' @param ...    arguments passed through to \code{\link{oclFunction}}
##' @return A vector of random numbers.
##' @export
rgammaOCL <- (function() {
  .rgamma_ocl_internal <- NULL
  function(n, shape, rate = 1, ...) {
    if (is.null(.rgamma_ocl_internal)) {
      .rgamma_ocl_internal <<- OpenCLeaR::oclFunction(
        signature = methods::signature(n = "integer", shape = "numeric", rate = "numeric"),
        kernel_file = "rgamma.cl", interface_file = "rgamma.cpp", ...
      )
    }
    return(.rgamma_ocl_internal(n, shape, rate))
  }
})()
