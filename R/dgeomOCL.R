if (getRversion() >= "2.15.1") {
    utils::globalVariables(".dgeom_ocl_internal")
}
##' Density calculation for a geometric distribution via OpenCL
##'
##' @name dgeomOCL
##' @param x     vector of quantiles.
##' @param prob  probability of success in each trial. 0 < prob <= 1.
##' @param ...   arguments passed through to \code{\link{oclFunction}}
##' @return A numeric vector of densities.
##' @export
dgeomOCL <- (function() {
  .dgeom_ocl_internal <- NULL
  function(x, prob, ...) {
    if (is.null(.dgeom_ocl_internal)) {
      .dgeom_ocl_internal <<- OpenCLeaR::oclFunction(
        signature = methods::signature(x = "numeric", prob = "numeric"),
        kernel_file = "dgeom.cl", interface_file = "dgeom.cpp", ...
      )
    }
    return(.dgeom_ocl_internal(x, prob))
  }
})()
