if (getRversion() >= "2.15.1") {
    utils::globalVariables(".qunif_ocl_internal")
}
##' Quantile function for a uniform distribution via OpenCL
##'
##' @name qunifOCL
##' @param p    vector of probabilities.
##' @param min  lower limit of the distribution.
##' @param max  upper limit of the distribution.
##' @param ...  arguments passed through to \code{\link{oclFunction}}
##' @return A numeric vector of quantiles.
##' @export
qunifOCL <- (function() {
  .qunif_ocl_internal <- NULL
  function(p, min = 0, max = 1, ...) {
    if (is.null(.qunif_ocl_internal)) {
      .qunif_ocl_internal <<- OpenCLeaR::oclFunction(
        signature = methods::signature(p = "numeric", min = "numeric", max = "numeric"),
        kernel_file = "qunif.cl",
        interface_file = "qunif.cpp",
        ...
      )
    }
    return(.qunif_ocl_internal(p, min, max))
  }
})()
