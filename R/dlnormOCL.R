if (getRversion() >= "2.15.1") {
    utils::globalVariables(".dlnorm_ocl_internal")
}
##' Density calculation for a log-normal distribution via OpenCL
##'
##' @name dlnormOCL
##' @param x        vector of quantiles.
##' @param meanlog  mean of the distribution on the log scale. Defaults to 0.
##' @param sdlog    standard deviation of the distribution on the log scale. Defaults to 1.
##' @param ...      arguments passed through to \code{\link{oclFunction}}
##' @return A numeric vector of densities.
##' @export
dlnormOCL <- (function() {
  .dlnorm_ocl_internal <- NULL
  function(x, meanlog = 0, sdlog = 1, ...) {
    if (is.null(.dlnorm_ocl_internal)) {
      .dlnorm_ocl_internal <<- OpenCLeaR::oclFunction(
        signature = methods::signature(x = "numeric", meanlog = "numeric", sdlog = "numeric"),
        kernel_file = "dlnorm.cl", interface_file = "dlnorm.cpp", ...
      )
    }
    return(.dlnorm_ocl_internal(x, meanlog, sdlog))
  }
})()
