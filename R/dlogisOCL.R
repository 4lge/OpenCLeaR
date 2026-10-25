if (getRversion() >= "2.15.1") {
    utils::globalVariables(".dlogis_ocl_internal")
}
##' Density calculation for a logistic distribution via OpenCL
##'
##' @name dlogisOCL
##' @param x         vector of quantiles.
##' @param location  location parameter. Defaults to 0.
##' @param scale     scale parameter (must be positive). Defaults to 1.
##' @param ...       arguments passed through to \code{\link{oclFunction}}
##' @return A numeric vector of densities.
##' @export
dlogisOCL <- (function() {
  .dlogis_ocl_internal <- NULL
  function(x, location = 0, scale = 1, ...) {
    if (is.null(.dlogis_ocl_internal)) {
      .dlogis_ocl_internal <<- OpenCLeaR::oclFunction(
        signature = methods::signature(x = "numeric", location = "numeric", scale = "numeric"),
        kernel_file = "dlogis.cl", interface_file = "dlogis.cpp", ...
      )
    }
    return(.dlogis_ocl_internal(x, location, scale))
  }
})()
