if (getRversion() >= "2.15.1") {
    utils::globalVariables(".pweibull_ocl_internal")
}
##' Distribution function for a Weibull distribution via OpenCL
##'
##' @name pweibullOCL
##' @param q      vector of quantiles.
##' @param shape  shape parameter (must be positive).
##' @param scale  scale parameter (must be positive, defaults to 1).
##' @param ...    arguments passed through to \code{\link{oclFunction}}
##' @return A numeric vector of probabilities.
##' @export
pweibullOCL <- (function() {
  .pweibull_ocl_internal <- NULL
  function(q, shape, scale = 1, ...) {
    if (is.null(.pweibull_ocl_internal)) {
      .pweibull_ocl_internal <<- OpenCLeaR::oclFunction(
        signature = methods::signature(q = "numeric", shape = "numeric", scale = "numeric"),
        kernel_file = "pweibull.cl", interface_file = "pweibull.cpp", ...
      )
    }
    return(.pweibull_ocl_internal(q, shape, scale))
  }
})()
