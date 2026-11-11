if (getRversion() >= "2.15.1") {
    utils::globalVariables(".pinvgamma_ocl_internal")
}
##' Distribution of the inverse gamma distribution via OpenCL
##'
##' @title Inverse gamma distribution (OpenCL accelerated)
##'
##' @description
##' This function calculates the cumulative distribution function
##' for the inverse gamma distribution on the active GPGPU device.
##'
##' @param q Vector of quantiles (input limits).
##' @param shape shape parameter (shape, alpha > 0).
##' @param rate Scale parameter via rate (Beta, alpha > 0). Alternatively can
##' often also \code{scale} can be specified (\code{rate = 1/scale}).
##' @param ... arguments passed through to \code{\link{oclFunction}}
##' @return
##' \code{pinvgammaOCL} returns one
##' returns a numeric vector of the same length as the input.
##'
##' @details
##' The calculations are outsourced to the OpenCL hardware. In
##' Background, the compiler uses those implemented in the stable log space
##' C functions of the GPGPU library. The random number generation is done via
##' a parallelized Mersenne twister (MT19937) directly in the VRAM.
##'
##' @seealso \code{\link{GetActiveDeviceInfo}}
##'
##' @export
pinvgammaOCL <- (function() {
  .pinvgamma_ocl_internal <- NULL
  function(q, shape, rate = 1, ...) {
    if (is.null(.pinvgamma_ocl_internal)) {
      .pinvgamma_ocl_internal <<- OpenCLeaR::oclFunction(
        signature = methods::signature(q = "numeric", shape = "numeric", rate = "numeric"),
        kernel_file = "pinvgamma.cl", interface_file = "pinvgamma.cpp", ...
      )
    }
    return(.pinvgamma_ocl_internal(q, shape, rate))
  }
})()

