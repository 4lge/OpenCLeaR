if (getRversion() >= "2.15.1") {
    utils::globalVariables(".rbinom_ocl_internal")
}
##' Random number generation from a binomial distribution via OpenCL
##' 
##' @param n Number of random values to generate
##' @param size  number of trials (zero or more).
##' @param prob  probability of success on each trial.
##' @param ...   arguments passed through to \code{\link{oclFunction}}
##' @export
rbinomOCL <- (function() {
  .rbinom_ocl_internal <- NULL
  function(n, size, prob, ...) {
    if (is.null(.rbinom_ocl_internal)) {
      .rbinom_ocl_internal <<- OpenCLeaR::oclFunction(
        signature = methods::signature(n = "integer", size = "integer", prob = "numeric"),
        kernel_file = "rbinom.cl", interface_file = "rbinom.cpp", ...
      )
    }
    return(.rbinom_ocl_internal(n, size, prob))
  }
})()
