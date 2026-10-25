if (getRversion() >= "2.15.1") {
    utils::globalVariables(".dcauchy_ocl_internal")
}
##' Density calculation for a Cauchy distribution via OpenCL
##'
##' @name dcauchyOCL
##' @param x         vector of quantiles.
##' @param location  location parameter. Defaults to 0.
##' @param scale     scale parameter (must be positive). Defaults to 1.
##' @param ...       arguments passed through to \code{\link{oclFunction}}
##' @return A numeric vector of densities.
##' @export
dcauchyOCL <- (function() {
  .dcauchy_ocl_internal <- NULL
  function(x, location = 0, scale = 1, ...) {
    if (is.null(.dcauchy_ocl_internal)) {
      .dcauchy_ocl_internal <<- OpenCLeaR::oclFunction(
        signature = methods::signature(x = "numeric", location = "numeric", scale = "numeric"),
        kernel_file = "dcauchy.cl", interface_file = "dcauchy.cpp", ...
      )
    }
    return(.dcauchy_ocl_internal(x, location, scale))
  }
})()
