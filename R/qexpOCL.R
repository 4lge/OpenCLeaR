if (getRversion() >= "2.15.1") {
    utils::globalVariables(".qexp_ocl_internal")
}
##' Quantile function for an exponential distribution via OpenCL
##'
##' @name qexpOCL
##' @param p     vector of probabilities.
##' @param rate  vector of rates (inverse scale).
##' @param ...   arguments passed through to \code{\link{oclFunction}}
##' @return A numeric vector of quantiles.
##' @export
qexpOCL <- (function() {
  .qexp_ocl_internal <- NULL
  function(p, rate = 1, ...) {
    if (is.null(.qexp_ocl_internal)) {
      .qexp_ocl_internal <<- OpenCLeaR::oclFunction(
        signature = methods::signature(p = "numeric", rate = "numeric"),
        kernel_file = "qexp.cl", interface_file = "qexp.cpp", ...
      )
    }
    return(.qexp_ocl_internal(p, rate))
  }
})()
