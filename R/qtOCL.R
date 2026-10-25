if (getRversion() >= "2.15.1") {
    utils::globalVariables(".qt_ocl_internal")
}
##' Quantile function for a Student-t distribution via OpenCL
##'
##' @name qtOCL
##' @param p   vector of probabilities.
##' @param df  degrees of freedom (infinitely positive, or large).
##' @param ... arguments passed through to \code{\link{oclFunction}}
##' @return A numeric vector of quantiles.
##' @export
qtOCL <- (function() {
  .qt_ocl_internal <- NULL
  function(p, df, ...) {
    if (is.null(.qt_ocl_internal)) {
      .qt_ocl_internal <<- OpenCLeaR::oclFunction(
        signature = methods::signature(p = "numeric", df = "integer"),
        kernel_file = "qt.cl", interface_file = "qt.cpp", ...
      )
    }
    return(.qt_ocl_internal(p, df))
  }
})()
