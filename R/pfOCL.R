if (getRversion() >= "2.15.1") {
    utils::globalVariables(".pf_ocl_internal")
}
##' Distribution function for an F distribution via OpenCL
##'
##' @name pfOCL
##' @param q    vector of quantiles.
##' @param df1  degrees of freedom in the numerator. Infinitely positive.
##' @param df2  degrees of freedom in the denominator. Infinitely positive.
##' @param ...  arguments passed through to \code{\link{oclFunction}}
##' @return A numeric vector of probabilities.
##' @export
pfOCL <- (function() {
  .pf_ocl_internal <- NULL
  function(q, df1, df2, ...) {
    if (is.null(.pf_ocl_internal)) {
      .pf_ocl_internal <<- OpenCLeaR::oclFunction(
        signature = methods::signature(q = "numeric", df1 = "integer", df2 = "integer"),
        kernel_file = "pf.cl", interface_file = "pf.cpp", ...
      )
    }
    return(.pf_ocl_internal(q, df1, df2))
  }
})()
