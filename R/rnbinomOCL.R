if (getRversion() >= "2.15.1") {
    utils::globalVariables(".rnbinom_ocl_internal")
}
##' Random number generation from a negative binomial distribution via OpenCL
##'
##' @name rnbinomOCL
##' @param n     count of random numbers to generate.
##' @param size  target for number of successful trials, or dispersion parameter (must be positive).
##' @param prob  probability of success in each trial. 0 < prob <= 1.
##' @param ...   arguments passed through to \code{\link{oclFunction}}
##' @return A vector of random numbers.
##' @export
rnbinomOCL <- (function() {
  .rnbinom_ocl_internal <- NULL
  function(n, size, prob, ...) {
    if (is.null(.rnbinom_ocl_internal)) {
      .rnbinom_ocl_internal <<- OpenCLeaR::oclFunction(
        signature = methods::signature(n = "integer", size = "integer", prob = "numeric"),
        kernel_file = "rnbinom.cl", interface_file = "rnbinom.cpp", ...
      )
    }
    return(.rnbinom_ocl_internal(n, size, prob))
  }
})()
