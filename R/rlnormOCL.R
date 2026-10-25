if (getRversion() >= "2.15.1") {
    utils::globalVariables(".rlnorm_ocl_internal")
}
##' Random number generation from a log-normal distribution via OpenCL
##'
##' @name rlnormOCL
##' @param n        count of random numbers to generate.
##' @param meanlog  mean of the distribution on the log scale. Defaults to 0.
##' @param sdlog    standard deviation of the distribution on the log scale. Defaults to 1.
##' @param ...      arguments passed through to \code{\link{oclFunction}}
##' @return A vector of random numbers.
##' @export
rlnormOCL <- (function() {
  .rlnorm_ocl_internal <- NULL
  function(n, meanlog = 0, sdlog = 1, ...) {
    if (is.null(.rlnorm_ocl_internal)) {
      .rlnorm_ocl_internal <<- OpenCLeaR::oclFunction(
        signature = methods::signature(n = "integer", meanlog = "numeric", sdlog = "numeric"),
        kernel_file = "rlnorm.cl", interface_file = "rlnorm.cpp", ...
      )
    }
    return(.rlnorm_ocl_internal(n, meanlog, sdlog))
  }
})()
