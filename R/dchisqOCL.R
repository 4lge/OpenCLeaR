if (getRversion() >= "2.15.1") {
    utils::globalVariables(".dchisq_ocl_internal")
}
##' Density calculation for a chi-squared distribution via OpenCL
##'
##' @name dchisqOCL
##' @param x   vector of quantiles.
##' @param df  degrees of freedom (infinitely positive).
##' @param ... arguments passed through to \code{\link{oclFunction}}
##' @return A numeric vector of densities.
##' @export
dchisqOCL <- (function() {
  .dchisq_ocl_internal <- NULL
  function(x, df, ...) {
    if (is.null(.dchisq_ocl_internal)) {
      .dchisq_ocl_internal <<- OpenCLeaR::oclFunction(
        signature = methods::signature(x = "numeric", df = "integer"),
        kernel_file = "dchisq.cl", interface_file = "dchisq.cpp", ...
      )
    }
    return(.dchisq_ocl_internal(x, df))
  }
})()
