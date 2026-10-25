if (getRversion() >= "2.15.1") {
    utils::globalVariables(".pchisq_ocl_internal")
}
##' Distribution function for a chi-squared distribution via OpenCL
##'
##' @name pchisqOCL
##' @param q   vector of quantiles.
##' @param df  degrees of freedom (infinitely positive).
##' @param ... arguments passed through to \code{\link{oclFunction}}
##' @return A numeric vector of probabilities.
##' @export
pchisqOCL <- (function() {
  .pchisq_ocl_internal <- NULL
  function(q, df, ...) {
    if (is.null(.pchisq_ocl_internal)) {
      .pchisq_ocl_internal <<- OpenCLeaR::oclFunction(
        signature = methods::signature(q = "numeric", df = "integer"),
        kernel_file = "pchisq.cl", interface_file = "pchisq.cpp", ...
      )
    }
    return(.pchisq_ocl_internal(q, df))
  }
})()
