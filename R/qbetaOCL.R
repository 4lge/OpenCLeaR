if (getRversion() >= "2.15.1") {
    utils::globalVariables(".qbeta_ocl_internal")
}
##' Quantile function for a beta distribution via OpenCL
##'
##' @name qbetaOCL
##' @param p       vector of probabilities.
##' @param shape1  non-negative parameter of the Beta distribution.
##' @param shape2  non-negative parameter of the Beta distribution.
##' @param ...     arguments passed through to \code{\link{oclFunction}}
##' @return A numeric vector of quantiles.
##' @export
qbetaOCL <- (function() {
  .qbeta_ocl_internal <- NULL
  function(p, shape1, shape2, ...) {
    if (is.null(.qbeta_ocl_internal)) {
      .qbeta_ocl_internal <<- OpenCLeaR::oclFunction(
        signature = methods::signature(p = "numeric", shape1 = "numeric", shape2 = "numeric"),
        kernel_file = "qbeta.cl", interface_file = "qbeta.cpp", ...
      )
    }
    return(.qbeta_ocl_internal(p, shape1, shape2))
  }
})()
