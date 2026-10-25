if (getRversion() >= "2.15.1") {
    utils::globalVariables(".rcauchy_ocl_internal")
}
##' Random number generation from a Cauchy distribution via OpenCL
##'
##' @name rcauchyOCL
##' @param n         count of random numbers to generate.
##' @param location  location parameter. Defaults to 0.
##' @param scale     scale parameter (must be positive). Defaults to 1.
##' @param ...       arguments passed through to \code{\link{oclFunction}}
##' @return A vector of random numbers.
##' @export
rcauchyOCL <- (function() {
  .rcauchy_ocl_internal <- NULL
  function(n, location = 0, scale = 1, ...) {
    if (is.null(.rcauchy_ocl_internal)) {
      .rcauchy_ocl_internal <<- OpenCLeaR::oclFunction(
        signature = methods::signature(n = "integer", location = "numeric", scale = "numeric"),
        kernel_file = "rcauchy.cl", interface_file = "rcauchy.cpp", ...
      )
    }
    return(.rcauchy_ocl_internal(n, location, scale))
  }
})()
