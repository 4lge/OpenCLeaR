if (getRversion() >= "2.15.1") {
    utils::globalVariables(".plnorm_ocl_internal")
}
##' Distribution function for a log-normal distribution via OpenCL
##'
##' @name plnormOCL
##' @param q        vector of quantiles.
##' @param meanlog  mean of the distribution on the log scale. Defaults to 0.
##' @param sdlog    standard deviation of the distribution on the log scale. Defaults to 1.
##' @param ...      arguments passed through to \code{\link{oclFunction}}
##' @return A numeric vector of probabilities.
##' @export
plnormOCL <- (function() {
  .plnorm_ocl_internal <- NULL
  function(q, meanlog = 0, sdlog = 1, ...) {
    if (is.null(.plnorm_ocl_internal)) {
      .plnorm_ocl_internal <<- OpenCLeaR::oclFunction(
        signature = methods::signature(q = "numeric", meanlog = "numeric", sdlog = "numeric"),
        kernel_file = "plnorm.cl", interface_file = "plnorm.cpp", ...
      )
    }
    return(.plnorm_ocl_internal(q, meanlog, sdlog))
  }
})()
