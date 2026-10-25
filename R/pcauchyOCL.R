if (getRversion() >= "2.15.1") {
    utils::globalVariables(".pcauchy_ocl_internal")
}
##' Distribution function for a Cauchy distribution via OpenCL
##'
##' @name pcauchyOCL
##' @param q         vector of quantiles.
##' @param location  location parameter. Defaults to 0.
##' @param scale     scale parameter (must be positive). Defaults to 1.
##' @param ...       arguments passed through to \code{\link{oclFunction}}
##' @return A numeric vector of probabilities.
##' @export
pcauchyOCL <- (function() {
  .pcauchy_ocl_internal <- NULL
  function(q, location = 0, scale = 1, ...) {
    if (is.null(.pcauchy_ocl_internal)) {
      .pcauchy_ocl_internal <<- OpenCLeaR::oclFunction(
        signature = methods::signature(q = "numeric", location = "numeric", scale = "numeric"),
        kernel_file = "pcauchy.cl", interface_file = "pcauchy.cpp", ...
      )
    }
    return(.pcauchy_ocl_internal(q, location, scale))
  }
})()
