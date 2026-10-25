if (getRversion() >= "2.15.1") {
    utils::globalVariables(".ppois_ocl_internal")
}
##' Distribution function for a Poisson distribution via OpenCL
##'
##' @name ppoisOCL
##' @param q       vector of quantiles.
##' @param lambda  vector of (non-negative) means.
##' @param ...     arguments passed through to \code{\link{oclFunction}}
##' @return A numeric vector of probabilities.
##' @export
ppoisOCL <- (function() {
  .ppois_ocl_internal <- NULL
  function(q, lambda, ...) {
    if (is.null(.ppois_ocl_internal)) {
      .ppois_ocl_internal <<- OpenCLeaR::oclFunction(
        signature = methods::signature(q = "numeric", lambda = "numeric"),
        kernel_file = "ppois.cl", interface_file = "ppois.cpp", ...
      )
    }
    return(.ppois_ocl_internal(q, lambda))
  }
})()
