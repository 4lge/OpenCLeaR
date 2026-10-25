if (getRversion() >= "2.15.1") {
    utils::globalVariables(".dhyper_ocl_internal")
}
##' Density calculation for a hypergeometric distribution via OpenCL
##'
##' @name dhyperOCL
##' @param x      vector of quantiles.
##' @param m      the number of white balls in the urn.
##' @param n      the number of black balls in the urn.
##' @param k      the number of balls drawn from the urn.
##' @param ...    arguments passed through to \code{\link{oclFunction}}
##' @return A numeric vector of densities.
##' @export
dhyperOCL <- (function() {
  .dhyper_ocl_internal <- NULL
  function(x, m, n, k, ...) {
    if (is.null(.dhyper_ocl_internal)) {
      .dhyper_ocl_internal <<- OpenCLeaR::oclFunction(
        signature = methods::signature(x = "numeric", m = "integer", n = "integer", k = "integer"),
        kernel_file = "dhyper.cl", interface_file = "dhyper.cpp", ...
      )
    }
    return(.dhyper_ocl_internal(x, m, n, k))
  }
})()
