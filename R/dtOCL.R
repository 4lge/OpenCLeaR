if (getRversion() >= "2.15.1") {
    utils::globalVariables(".dt_ocl_internal")
}
##' Density calculation for a Student-t distribution via OpenCL
##'
##' @name dtOCL
##' @param x   vector of quantiles.
##' @param df  degrees of freedom (infinitely positive, or large).
##' @param ... arguments passed through to \code{\link{oclFunction}}
##' @return A numeric vector of densities.
##' @export
dtOCL <- (function() {
  .dt_ocl_internal <- NULL
  function(x, df, ...) {
    if (is.null(.dt_ocl_internal)) {
      .dt_ocl_internal <<- OpenCLeaR::oclFunction(
        signature = methods::signature(x = "numeric", df = "integer"),
        kernel_file = "dt.cl", interface_file = "dt.cpp", ...
      )
    }
    return(.dt_ocl_internal(x, df))
  }
})()
