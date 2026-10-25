if (getRversion() >= "2.15.1") {
    utils::globalVariables(".qgamma_ocl_internal")
}
##' Quantile function for a gamma distribution via OpenCL
##'
##' @name qgammaOCL
##' @param p      vector of probabilities.
##' @param shape  shape parameter (must be positive).
##' @param rate   inverse scale parameter (must be positive).
##' @param ...    arguments passed through to \code{\link{oclFunction}}
##' @return A numeric vector of quantiles.
##' @export
qgammaOCL <- (function() {
  .qgamma_ocl_internal <- NULL
  function(p, shape, rate = 1, ...) {
    if (is.null(.qgamma_ocl_internal)) {
      .qgamma_ocl_internal <<- OpenCLeaR::oclFunction(
        signature = methods::signature(p = "numeric", shape = "numeric", rate = "numeric"),
        kernel_file = "qgamma.cl", interface_file = "qgamma.cpp", ...
      )
    }
    return(.qgamma_ocl_internal(p, shape, rate))
  }
})()
