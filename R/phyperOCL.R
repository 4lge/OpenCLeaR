if (getRversion() >= "2.15.1") {
    utils::globalVariables(".phyper_ocl_internal")
}
##' Distribution function for a hypergeometric distribution via OpenCL
##'
##' @name phyperOCL
##' @param q      vector of quantiles.
##' @param m      the number of white balls in the urn.
##' @param n      the number of black balls in the urn.
##' @param k      the number of balls drawn from the urn.
##' @param ...    arguments passed through to \code{\link{oclFunction}}
##' @return A numeric vector of probabilities.
##' @export
phyperOCL <- (function() {
  .phyper_ocl_internal <- NULL
  function(q, m, n, k, ...) {
    if (is.null(.phyper_ocl_internal)) {
      .phyper_ocl_internal <<- OpenCLeaR::oclFunction(
        signature = methods::signature(q = "numeric", m = "integer", n = "integer", k = "integer"),
        kernel_file = "phyper.cl", interface_file = "phyper.cpp", ...
      )
    }
    return(.phyper_ocl_internal(q, m, n, k))
  }
})()
