if (getRversion() >= "2.15.1") {
    utils::globalVariables(".pt_ocl_internal")
}
##' Distribution function for a Student-t distribution via OpenCL
##'
##' @name ptOCL
##' @param q   vector of quantiles.
##' @param df  degrees of freedom (infinitely positive, or large).
##' @param ... arguments passed through to \code{\link{oclFunction}}
##' @return A numeric vector of probabilities.
##' @export
ptOCL <- (function() {
  .pt_ocl_internal <- NULL
  function(q, df, ...) {
    if (is.null(.pt_ocl_internal)) {
      .pt_ocl_internal <<- OpenCLeaR::oclFunction(
        signature = methods::signature(q = "numeric", df = "integer"),
        kernel_file = "pt.cl", interface_file = "pt.cpp", ...
      )
    }
    return(.pt_ocl_internal(q, df))
  }
})()
