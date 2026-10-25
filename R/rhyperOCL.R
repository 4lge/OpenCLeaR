if (getRversion() >= "2.15.1") {
    utils::globalVariables(".rhyper_ocl_internal")
}
##' Random number generation from a hypergeometric distribution via OpenCL
##'
##' @name rhyperOCL
##' @param nn      count of random numbers to generate.
##' @param m      the number of white balls in the urn.
##' @param n      the number of black balls in the urn.
##' @param k      the number of balls drawn from the urn.
##' @param ...    arguments passed through to \code{\link{oclFunction}}
##' @return A vector of random numbers.
##' @export
rhyperOCL <- (function() {
  .rhyper_ocl_internal <- NULL
  function(nn, m, n, k, ...) {
    if (is.null(.rhyper_ocl_internal)) {
      .rhyper_ocl_internal <<- OpenCLeaR::oclFunction(
        signature = methods::signature(nn = "integer", m = "numeric", n = "numeric", k = "numeric"),
        kernel_file = "rhyper.cl", interface_file = "rhyper.cpp", ...
      )
    }
    return(.rhyper_ocl_internal(nn, m, n, k))
  }
})()
