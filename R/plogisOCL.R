if (getRversion() >= "2.15.1") {
    utils::globalVariables(".plogis_ocl_internal")
}
##' Distribution function for a logistic distribution via OpenCL
##'
##' @name plogisOCL
##' @param q         vector of quantiles.
##' @param location  location parameter. Defaults to 0.
##' @param scale     scale parameter (must be positive). Defaults to 1.
##' @param ...       arguments passed through to \code{\link{oclFunction}}
##' @return A numeric vector of probabilities.
##' @export
plogisOCL <- (function() {
  .plogis_ocl_internal <- NULL
  function(q, location = 0, scale = 1, ...) {
    if (is.null(.plogis_ocl_internal)) {
      .plogis_ocl_internal <<- OpenCLeaR::oclFunction(
        signature = methods::signature(q = "numeric", location = "numeric", scale = "numeric"),
        kernel_file = "plogis.cl", interface_file = "plogis.cpp", ...
      )
    }
    return(.plogis_ocl_internal(q, location, scale))
  }
})()
