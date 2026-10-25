if (getRversion() >= "2.15.1") {
    utils::globalVariables(".dpois_ocl_internal")
}
##' Density calculation for a Poisson distribution via OpenCL
##'
##' @name dpoisOCL
##' @param x       vector of (non-negative integer) quantiles.
##' @param lambda  vector of (non-negative) means.
##' @param ...     arguments passed through to \code{\link{oclFunction}}
##' @return A numeric vector of densities.
##' @export
dpoisOCL <- (function() {
  .dpois_ocl_internal <- NULL
  function(x, lambda, ...) {
    if (is.null(.dpois_ocl_internal)) {
      .dpois_ocl_internal <<- OpenCLeaR::oclFunction(
        signature = methods::signature(x = "numeric", lambda = "numeric"),
        kernel_file = "dpois.cl", interface_file = "dpois.cpp", ...
      )
    }
    return(.dpois_ocl_internal(x, lambda))
  }
})()
