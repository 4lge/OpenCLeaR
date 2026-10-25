if (getRversion() >= "2.15.1") {
    utils::globalVariables(".qpois_ocl_internal")
}
##' Quantile function for a Poisson distribution via OpenCL
##'
##' @name qpoisOCL
##' @param p       vector of probabilities.
##' @param lambda  vector of (non-negative) means.
##' @param ...     arguments passed through to \code{\link{oclFunction}}
##' @return A numeric vector of quantiles.
##' @export
qpoisOCL <- (function() {
  .qpois_ocl_internal <- NULL
  function(p, lambda, ...) {
    if (is.null(.qpois_ocl_internal)) {
      .qpois_ocl_internal <<- OpenCLeaR::oclFunction(
        signature = methods::signature(p = "numeric", lambda = "numeric"),
        kernel_file = "qpois.cl", interface_file = "qpois.cpp", ...
      )
    }
    return(.qpois_ocl_internal(p, lambda))
  }
})()
