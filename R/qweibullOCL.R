if (getRversion() >= "2.15.1") {
    utils::globalVariables(".qweibull_ocl_internal")
}
##' Quantile function for a Weibull distribution via OpenCL
##'
##' @name qweibullOCL
##' @param p      vector of probabilities.
##' @param shape  shape parameter (must be positive).
##' @param scale  scale parameter (must be positive, defaults to 1).
##' @param ...    arguments passed through to \code{\link{oclFunction}}
##' @return A numeric vector of quantiles.
##' @export
qweibullOCL <- (function() {
  .qweibull_ocl_internal <- NULL
  function(p, shape, scale = 1, ...) {
    if (is.null(.qweibull_ocl_internal)) {
      .qweibull_ocl_internal <<- OpenCLeaR::oclFunction(
        signature = methods::signature(p = "numeric", shape = "numeric", scale = "numeric"),
        kernel_file = "qweibull.cl", interface_file = "qweibull.cpp", ...
      )
    }
    return(.qweibull_ocl_internal(p, shape, scale))
  }
})()
