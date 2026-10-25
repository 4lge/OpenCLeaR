if (getRversion() >= "2.15.1") {
    utils::globalVariables(".qcauchy_ocl_internal")
}
##' Quantile function for a Cauchy distribution via OpenCL
##'
##' @name qcauchyOCL
##' @param p         vector of probabilities.
##' @param location  location parameter. Defaults to 0.
##' @param scale     scale parameter (must be positive). Defaults to 1.
##' @param ...       arguments passed through to \code{\link{oclFunction}}
##' @return A numeric vector of quantiles.
##' @export
qcauchyOCL <- (function() {
  .qcauchy_ocl_internal <- NULL
  function(p, location = 0, scale = 1, ...) {
    if (is.null(.qcauchy_ocl_internal)) {
      .qcauchy_ocl_internal <<- OpenCLeaR::oclFunction(
        signature = methods::signature(p = "numeric", location = "numeric", scale = "numeric"),
        kernel_file = "qcauchy.cl", interface_file = "qcauchy.cpp", ...
      )
    }
    return(.qcauchy_ocl_internal(p, location, scale))
  }
})()
