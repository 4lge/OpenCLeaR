if (getRversion() >= "2.15.1") {
    utils::globalVariables(".pgamma_ocl_internal")
}
##' Distribution function for a gamma distribution via OpenCL
##'
##' @name pgammaOCL
##' @param q      vector of quantiles.
##' @param shape  shape parameter (must be positive).
##' @param rate   inverse scale parameter (must be positive).
##' @param ...    arguments passed through to \code{\link{oclFunction}}
##' @return A numeric vector of probabilities.
##' @export
pgammaOCL <- (function() {
  .pgamma_ocl_internal <- NULL
  function(q, shape, rate = 1, ...) {
    if (is.null(.pgamma_ocl_internal)) {
      .pgamma_ocl_internal <<- OpenCLeaR::oclFunction(
        signature = methods::signature(q = "numeric", shape = "numeric", rate = "numeric"),
        kernel_file = "pgamma.cl", interface_file = "pgamma.cpp", ...
      )
    }
    return(.pgamma_ocl_internal(q, shape, rate))
  }
})()
