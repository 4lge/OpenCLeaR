if (getRversion() >= "2.15.1") {
    utils::globalVariables(".pbinom_ocl_internal")
}
##' Distribution function for a binomial distribution via OpenCL
##'
##' @name pbinomOCL
##' @param q     vector of quantiles.
##' @param size  number of trials (zero or more).
##' @param prob  probability of success on each trial.
##' @param ...   arguments passed through to \code{\link{oclFunction}}
##' @return A numeric vector of probabilities.
##' @export
pbinomOCL <- (function() {
  .pbinom_ocl_internal <- NULL
  function(q, size, prob, ...) {
    if (is.null(.pbinom_ocl_internal)) {
      .pbinom_ocl_internal <<- OpenCLeaR::oclFunction(
        signature = methods::signature(q = "numeric", size = "integer", prob = "numeric"),
        kernel_file = "pbinom.cl", interface_file = "pbinom.cpp", ...
      )
    }
    return(.pbinom_ocl_internal(q, size, prob))
  }
})()
