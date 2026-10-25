if (getRversion() >= "2.15.1") {
    utils::globalVariables(".qf_ocl_internal")
}
##' Quantile function for an F distribution via OpenCL
##'
##' @name qfOCL
##' @param p    vector of probabilities.
##' @param df1  degrees of freedom in the numerator. Infinitely positive.
##' @param df2  degrees of freedom in the denominator. Infinitely positive.
##' @param ...  arguments passed through to \code{\link{oclFunction}}
##' @return A numeric vector of quantiles.
##' @export
qfOCL <- (function() {
  .qf_ocl_internal <- NULL
  function(p, df1, df2, ...) {
    if (is.null(.qf_ocl_internal)) {
      .qf_ocl_internal <<- OpenCLeaR::oclFunction(
        signature = methods::signature(p = "numeric", df1 = "integer", df2 = "integer"),
        kernel_file = "qf.cl", interface_file = "qf.cpp", ...
      )
    }
    return(.qf_ocl_internal(p, df1, df2))
  }
})()
