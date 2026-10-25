if (getRversion() >= "2.15.1") {
    utils::globalVariables(".dweibull_ocl_internal")
}
##' Density calculation for a Weibull distribution via OpenCL
##'
##' @name dweibullOCL
##' @param x      vector of quantiles.
##' @param shape  shape parameter (must be positive).
##' @param scale  scale parameter (must be positive, defaults to 1).
##' @param ...    arguments passed through to \code{\link{oclFunction}}
##' @return A numeric vector of densities.
##' @export
dweibullOCL <- (function() {
  .dweibull_ocl_internal <- NULL
  function(x, shape, scale = 1, ...) {
    if (is.null(.dweibull_ocl_internal)) {
      .dweibull_ocl_internal <<- OpenCLeaR::oclFunction(
        signature = methods::signature(x = "numeric", shape = "numeric", scale = "numeric"),
        kernel_file = "dweibull.cl", interface_file = "dweibull.cpp", ...
      )
    }
    return(.dweibull_ocl_internal(x, shape, scale))
  }
})()
