if (getRversion() >= "2.15.1") {
    utils::globalVariables(".dunif_ocl_internal")
}
##' Density calculation for a uniform distribution via OpenCL
##'
##' @name dunifOCL
##' @param x    vector of quantiles.
##' @param min  lower limit of the distribution.
##' @param max  upper limit of the distribution.
##' @param ...  arguments passed through to \code{\link{oclFunction}}
##' @return A numeric vector of densities.
##' @export
dunifOCL <- (function() {
  .dunif_ocl_internal <- NULL
  function(x, min = 0, max = 1, ...) {
    if (is.null(.dunif_ocl_internal)) {
      .dunif_ocl_internal <<- OpenCLeaR::oclFunction(
        signature = methods::signature(x = "numeric", min = "numeric", max = "numeric"),
        kernel_file = "dunif.cl",
        interface_file = "dunif.cpp",
        ...
      )
    }
    return(.dunif_ocl_internal(x, min, max))
  }
})()
