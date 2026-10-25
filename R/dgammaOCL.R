if (getRversion() >= "2.15.1") {
    utils::globalVariables(".dgamma_ocl_internal")
}
##' Density calculation for a gamma distribution via OpenCL
##'
##' @name dgammaOCL
##' @param x      vector of quantiles.
##' @param shape  shape parameter (must be positive).
##' @param rate   inverse scale parameter (must be positive).
##' @param ...    arguments passed through to \code{\link{oclFunction}}
##' @return A numeric vector of densities.
##' @export
dgammaOCL <- (function() {
  .dgamma_ocl_internal <- NULL
  function(x, shape, rate = 1, ...) {
    if (is.null(.dgamma_ocl_internal)) {
      .dgamma_ocl_internal <<- OpenCLeaR::oclFunction(
        signature = methods::signature(x = "numeric", shape = "numeric", rate = "numeric"),
        kernel_file = "dgamma.cl", interface_file = "dgamma.cpp", ...
      )
    }
    return(.dgamma_ocl_internal(x, shape, rate))
  }
})()
