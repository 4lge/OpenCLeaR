if (getRversion() >= "2.15.1") {
    utils::globalVariables(".dinvgamma_ocl_internal")
}
##' Density of the inverse gamma distribution via OpenCL
##'
##' @title Inverse gamma distribution (OpenCL accelerated)
##'
##' @description
##' This function calculates the density for the inverse gamma distribution on the active GPGPU device.
##'
##' @param x vector of quantiles (input limits).
##' @param shape shape parameter (shape, alpha > 0).
##' @param rate Scale parameter via rate (Beta, alpha > 0). Alternatively can
##' often also \code{scale} can be specified (\code{rate = 1/scale}).
##' @param ... arguments passed through to \code{\link{oclFunction}}
##' @return
##' \code{dinvgammaOCL} returns one
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
dinvgammaOCL <- (function() {
  .dinvgamma_ocl_internal <- NULL
  function(x, shape, rate = 1, ...) {
    if (is.null(.dinvgamma_ocl_internal)) {
      .dinvgamma_ocl_internal <<- OpenCLeaR::oclFunction(
        signature = methods::signature(x = "numeric", shape = "numeric", rate = "numeric"),
        kernel_file = "dinvgamma.cl", interface_file = "dinvgamma.cpp", ...
      )
    }
    return(.dinvgamma_ocl_internal(x, shape, rate))
  }
})()

