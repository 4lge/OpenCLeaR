if (getRversion() >= "2.15.1") {
    utils::globalVariables(".rf_ocl_internal")
}
##' Random number generation from an F distribution via OpenCL
##'
##' @name rfOCL
##' @param n    count of random numbers to generate.
##' @param df1  degrees of freedom in the numerator. Infinitely positive.
##' @param df2  degrees of freedom in the denominator. Infinitely positive.
##' @param ...  arguments passed through to \code{\link{oclFunction}}
##' @return A vector of random numbers.
##' @export
rfOCL <- (function() {
  .rf_ocl_internal <- NULL
  function(n, df1, df2, ...) {
    if (is.null(.rf_ocl_internal)) {
      .rf_ocl_internal <<- OpenCLeaR::oclFunction(
        signature = methods::signature(n = "integer", df1 = "integer", df2 = "integer"),
        kernel_file = "rf.cl", interface_file = "rf.cpp", ...
      )
    }
    return(.rf_ocl_internal(n, df1, df2))
  }
})()
