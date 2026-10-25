if (getRversion() >= "2.15.1") {
    utils::globalVariables(".qgeom_ocl_internal")
}
##' Quantile function for a geometric distribution via OpenCL
##'
##' @name qgeomOCL
##' @param p     vector of probabilities.
##' @param prob  probability of success in each trial. 0 < prob <= 1.
##' @param ...   arguments passed through to \code{\link{oclFunction}}
##' @return A numeric vector of quantiles.
##' @export
qgeomOCL <- (function() {
  .qgeom_ocl_internal <- NULL
  function(p, prob, ...) {
    if (is.null(.qgeom_ocl_internal)) {
      .qgeom_ocl_internal <<- OpenCLeaR::oclFunction(
        signature = methods::signature(p = "numeric", prob = "numeric"),
        kernel_file = "qgeom.cl", interface_file = "qgeom.cpp", ...
      )
    }
    return(.qgeom_ocl_internal(p, prob))
  }
})()
