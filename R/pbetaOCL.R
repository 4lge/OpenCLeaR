if (getRversion() >= "2.15.1") {
    utils::globalVariables(".pbeta_ocl_internal")
}
##' Distribution function for a beta distribution via OpenCL
##'
##' @name pbetaOCL
##' @param q       vector of quantiles.
##' @param shape1  non-negative parameter of the Beta distribution.
##' @param shape2  non-negative parameter of the Beta distribution.
##' @param ...     arguments passed through to \code{\link{oclFunction}}
##' @return A numeric vector of probabilities.
##' @export
pbetaOCL <- (function() {
  .pbeta_ocl_internal <- NULL
  function(q, shape1, shape2, ...) {
    if (is.null(.pbeta_ocl_internal)) {
      .pbeta_ocl_internal <<- OpenCLeaR::oclFunction(
        signature = methods::signature(q = "numeric", shape1 = "numeric", shape2 = "numeric"),
        kernel_file = "pbeta.cl", interface_file = "pbeta.cpp", ...
      )
    }
    return(.pbeta_ocl_internal(q, shape1, shape2))
  }
})()
