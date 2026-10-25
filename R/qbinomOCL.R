if (getRversion() >= "2.15.1") {
    utils::globalVariables(".qbinom_ocl_internal")
}
##' Quantile function for a binomial distribution via OpenCL
##'
##' @name qbinomOCL
##' @param p     vector of probabilities.
##' @param size  number of trials (zero or more).
##' @param prob  probability of success on each trial.
##' @param ...   arguments passed through to \code{\link{oclFunction}}
##' @return A numeric vector of quantiles.
##' @export
qbinomOCL <- (function() {
  .qbinom_ocl_internal <- NULL
  function(p, size, prob, ...) {
    if (is.null(.qbinom_ocl_internal)) {
      .qbinom_ocl_internal <<- OpenCLeaR::oclFunction(
        signature = methods::signature(p = "numeric", size = "integer", prob = "numeric"),
        kernel_file = "qbinom.cl", interface_file = "qbinom.cpp", ...
      )
    }
    return(.qbinom_ocl_internal(p, size, prob))
  }
})()
