if (getRversion() >= "2.15.1") {
    utils::globalVariables(".qnbinom_ocl_internal")
}
##' Quantile function for a negative binomial distribution via OpenCL
##'
##' @name qnbinomOCL
##' @param p     vector of probabilities.
##' @param size  target for number of successful trials, or dispersion parameter (must be positive).
##' @param prob  probability of success in each trial. 0 < prob <= 1.
##' @param ...   arguments passed through to \code{\link{oclFunction}}
##' @return A numeric vector of quantiles.
##' @export
qnbinomOCL <- (function() {
  .qnbinom_ocl_internal <- NULL
  function(p, size, prob, ...) {
    if (is.null(.qnbinom_ocl_internal)) {
      .qnbinom_ocl_internal <<- OpenCLeaR::oclFunction(
        signature = methods::signature(p = "numeric", size = "integer", prob = "numeric"),
        kernel_file = "qnbinom.cl", interface_file = "qnbinom.cpp", ...
      )
    }
    return(.qnbinom_ocl_internal(p, size, prob))
  }
})()
