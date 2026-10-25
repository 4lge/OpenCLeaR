if (getRversion() >= "2.15.1") {
    utils::globalVariables(".pnbinom_ocl_internal")
}
##' Distribution function for a negative binomial distribution via OpenCL
##'
##' @name pnbinomOCL
##' @param q     vector of quantiles.
##' @param size  target for number of successful trials, or dispersion parameter (must be positive).
##' @param prob  probability of success in each trial. 0 < prob <= 1.
##' @param ...   arguments passed through to \code{\link{oclFunction}}
##' @return A numeric vector of probabilities.
##' @export
pnbinomOCL <- (function() {
  .pnbinom_ocl_internal <- NULL
  function(q, size, prob, ...) {
    if (is.null(.pnbinom_ocl_internal)) {
      .pnbinom_ocl_internal <<- OpenCLeaR::oclFunction(
        signature = methods::signature(q = "numeric", size = "integer", prob = "numeric"),
        kernel_file = "pnbinom.cl", interface_file = "pnbinom.cpp", ...
      )
    }
    return(.pnbinom_ocl_internal(q, size, prob))
  }
})()
