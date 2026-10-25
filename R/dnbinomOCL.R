if (getRversion() >= "2.15.1") {
    utils::globalVariables(".dnbinom_ocl_internal")
}
##' Density calculation for a negative binomial distribution via OpenCL
##'
##' @name dnbinomOCL
##' @param x     vector of quantiles.
##' @param size  target for number of successful trials, or dispersion parameter (must be positive).
##' @param prob  probability of success in each trial. 0 < prob <= 1.
##' @param ...   arguments passed through to \code{\link{oclFunction}}
##' @return A numeric vector of densities.
##' @export
dnbinomOCL <- (function() {
  .dnbinom_ocl_internal <- NULL
  function(x, size, prob, ...) {
    if (is.null(.dnbinom_ocl_internal)) {
      .dnbinom_ocl_internal <<- OpenCLeaR::oclFunction(
        signature = methods::signature(x = "numeric", size = "integer", prob = "numeric"),
        kernel_file = "dnbinom.cl", interface_file = "dnbinom.cpp", ...
      )
    }
    return(.dnbinom_ocl_internal(x, size, prob))
  }
})()
