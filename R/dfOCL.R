if (getRversion() >= "2.15.1") {
    utils::globalVariables(".df_ocl_internal")
}
##' Density calculation for an F distribution via OpenCL
##'
##' @name dfOCL
##' @param x    vector of quantiles.
##' @param df1  degrees of freedom in the numerator. Infinitely positive.
##' @param df2  degrees of freedom in the denominator. Infinitely positive.
##' @param ...  arguments passed through to \code{\link{oclFunction}}
##' @return A numeric vector of densities.
##' @export
dfOCL <- (function() {
  .df_ocl_internal <- NULL
  function(x, df1, df2, ...) {
    if (is.null(.df_ocl_internal)) {
      .df_ocl_internal <<- OpenCLeaR::oclFunction(
        signature = methods::signature(x = "numeric", df1 = "integer", df2 = "integer"),
        kernel_file = "df.cl", interface_file = "df.cpp", ...
      )
    }
    return(.df_ocl_internal(x, df1, df2))
  }
})()
