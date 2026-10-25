if (getRversion() >= "2.15.1") {
    utils::globalVariables(".qchisq_ocl_internal")
}
##' Quantile function for a chi-squared distribution via OpenCL
##'
##' @name qchisqOCL
##' @param p   vector of probabilities.
##' @param df  degrees of freedom (infinitely positive).
##' @param ... arguments passed through to \code{\link{oclFunction}}
##' @return A numeric vector of quantiles.
##' @export
qchisqOCL <- (function() {
  .qchisq_ocl_internal <- NULL
  function(p, df, ...) {
    if (is.null(.qchisq_ocl_internal)) {
      .qchisq_ocl_internal <<- OpenCLeaR::oclFunction(
        signature = methods::signature(p = "numeric", df = "integer"),
        kernel_file = "qchisq.cl", interface_file = "qchisq.cpp", ...
      )
    }
    return(.qchisq_ocl_internal(p, df))
  }
})()
