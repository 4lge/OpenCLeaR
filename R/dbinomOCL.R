if (getRversion() >= "2.15.1") {
    utils::globalVariables(".dbinom_ocl_internal")
}
##' Density calculation for a binomial distribution via OpenCL
##'
##' @name dbinomOCL
##' @param x     vector of quantiles.
##' @param size  number of trials (zero or more).
##' @param prob  probability of success on each trial.
##' @param ...   arguments passed through to \code{\link{oclFunction}}
##' @return A numeric vector of densities.
##' @export
dbinomOCL <- (function() {
  .dbinom_ocl_internal <- NULL
  function(x, size, prob, ...) {
    if (is.null(.dbinom_ocl_internal)) {
      .dbinom_ocl_internal <<- OpenCLeaR::oclFunction(
        signature = methods::signature(x = "numeric", size = "integer", prob = "numeric"),
        kernel_file = "dbinom.cl", interface_file = "dbinom.cpp", ...
      )
    }
    return(.dbinom_ocl_internal(x, size, prob))
  }
})()
