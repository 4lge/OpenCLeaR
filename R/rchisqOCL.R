if (getRversion() >= "2.15.1") {
    utils::globalVariables(".rchisq_ocl_internal")
}
##' Random number generation from a chi-squared distribution via OpenCL
##'
##' @name rchisqOCL
##' @param n   count of random numbers to generate.
##' @param df  degrees of freedom (infinitely positive).
##' @param ... arguments passed through to \code{\link{oclFunction}}
##' @return A vector of random numbers.
##' @export
rchisqOCL <- (function() {
  .rchisq_ocl_internal <- NULL
  function(n, df, ...) {
    if (is.null(.rchisq_ocl_internal)) {
      .rchisq_ocl_internal <<- OpenCLeaR::oclFunction(
        signature = methods::signature(n = "integer", df = "integer"),
        kernel_file = "rchisq.cl", interface_file = "rchisq.cpp", ...
      )
    }
    return(.rchisq_ocl_internal(n, df))
  }
})()
