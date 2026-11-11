if (getRversion() >= "2.15.1") {
    utils::globalVariables(".rinvgamma_ocl_internal")
}

##' Random numbers of the inverse gamma distribution via OpenCL
##'
##' @title Inverse gamma distribution (OpenCL accelerated)
##'
##' @description
##' This function generates random numbers (\code{rinvgammaOCL})
##' for the inverse gamma distribution on the active GPGPU device.
##'
##' @param n Number of random numbers to generate.
##' @param shape shape parameter (shape, alpha > 0).
##' @param rate Scale parameter via rate (Beta, alpha > 0). Alternatively can
##' often also \code{scale} can be specified (\code{rate = 1/scale}).
##' @param ... arguments passed through to \code{\link{oclFunction}}
##' @return
##' \code{rinvgammaOCL} returns a numerical vector of length \code{n}.
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
rinvgammaOCL <- (function() {
  .rinvgamma_ocl_internal <- NULL
  function(n, shape, rate = 1, ...) {
    if (is.null(.rinvgamma_ocl_internal)) {
      .rinvgamma_ocl_internal <<- OpenCLeaR::oclFunction(
        signature = methods::signature(n = "integer", shape = "numeric", rate = "numeric"),
        kernel_file = "rinvgamma.cl", interface_file = "rinvgamma.cpp", ...
      )
    }
    return(.rinvgamma_ocl_internal(n, shape, rate))
  }
})()
