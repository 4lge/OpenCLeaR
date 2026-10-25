if (getRversion() >= "2.15.1") {
    utils::globalVariables(".qlnorm_ocl_internal")
}
##' Quantile function for a log-normal distribution via OpenCL
##'
##' @name qlnormOCL
##' @param p        vector of probabilities.
##' @param meanlog  mean of the distribution on the log scale. Defaults to 0.
##' @param sdlog    standard deviation of the distribution on the log scale. Defaults to 1.
##' @param ...      arguments passed through to \code{\link{oclFunction}}
##' @return A numeric vector of quantiles.
##' @export
qlnormOCL <- (function() {
  .qlnorm_ocl_internal <- NULL
  function(p, meanlog = 0, sdlog = 1, ...) {
    if (is.null(.qlnorm_ocl_internal)) {
      .qlnorm_ocl_internal <<- OpenCLeaR::oclFunction(
        signature = methods::signature(p = "numeric", meanlog = "numeric", sdlog = "numeric"),
        kernel_file = "qlnorm.cl", interface_file = "qlnorm.cpp", ...
      )
    }
    return(.qlnorm_ocl_internal(p, meanlog, sdlog))
  }
})()
