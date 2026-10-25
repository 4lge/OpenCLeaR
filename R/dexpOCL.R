if (getRversion() >= "2.15.1") {
    utils::globalVariables(".dexp_ocl_internal")
}
##' Density calculation for an exponential distribution via OpenCL
##'
##' @name dexpOCL
##' @param x     vector of quantiles.
##' @param rate  vector of rates (inverse scale).
##' @param ...   arguments passed through to \code{\link{oclFunction}}
##' @return A numeric vector of densities.
##' @export
dexpOCL <- (function() {
  .dexp_ocl_internal <- NULL
  function(x, rate = 1, ...) {
    if (is.null(.dexp_ocl_internal)) {
      .dexp_ocl_internal <<- OpenCLeaR::oclFunction(
        signature = methods::signature(x = "numeric", rate = "numeric"),
        kernel_file = "dexp.cl", interface_file = "dexp.cpp", ...
      )
    }
    return(.dexp_ocl_internal(x, rate))
  }
})()
