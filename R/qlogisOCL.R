if (getRversion() >= "2.15.1") {
    utils::globalVariables(".qlogis_ocl_internal")
}
##' Quantile function for a logistic distribution via OpenCL
##'
##' @name qlogisOCL
##' @param p         vector of probabilities.
##' @param location  location parameter. Defaults to 0.
##' @param scale     scale parameter (must be positive). Defaults to 1.
##' @param ...       arguments passed through to \code{\link{oclFunction}}
##' @return A numeric vector of quantiles.
##' @export
qlogisOCL <- (function() {
  .qlogis_ocl_internal <- NULL
  function(p, location = 0, scale = 1, ...) {
    if (is.null(.qlogis_ocl_internal)) {
      .qlogis_ocl_internal <<- OpenCLeaR::oclFunction(
        signature = methods::signature(p = "numeric", location = "numeric", scale = "numeric"),
        kernel_file = "qlogis.cl", interface_file = "qlogis.cpp", ...
      )
    }
    return(.qlogis_ocl_internal(p, location, scale))
  }
})()
