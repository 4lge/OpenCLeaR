if (getRversion() >= "2.15.1") {
    utils::globalVariables(".qhyper_ocl_internal")
}
##' Quantile function for a hypergeometric distribution via OpenCL
##'
##' @name qhyperOCL
##' @param p      vector of probabilities.
##' @param m      the number of white balls in the urn.
##' @param n      the number of black balls in the urn.
##' @param k      the number of balls drawn from the urn.
##' @param ...    arguments passed through to \code{\link{oclFunction}}
##' @return A numeric vector of quantiles.
##' @export
qhyperOCL <- (function() {
  .qhyper_ocl_internal <- NULL
  function(p, m, n, k, ...) {
    if (is.null(.qhyper_ocl_internal)) {
      .qhyper_ocl_internal <<- OpenCLeaR::oclFunction(
        signature = methods::signature(p = "numeric", m = "integer", n = "integer", k = "integer"),
        kernel_file = "qhyper.cl", interface_file = "qhyper.cpp", ...
      )
    }
    return(.qhyper_ocl_internal(p, m, n, k))
  }
})()
