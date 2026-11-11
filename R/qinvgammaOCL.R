if (getRversion() >= "2.15.1") {
    utils::globalVariables(".qinvgamma_ocl_internal")
}

##' Quantiles of the inverse gamma distribution via OpenCL
##'
##' @title Inverse gamma distribution (OpenCL accelerated)
##'
##' @description
##' This function calculates the quantile function
##' (\code{qinvgammaOCL})
##' for the inverse gamma distribution on the active GPGPU device.
##'
##' @param p Vector of probabilities.
##' @param shape shape parameter (shape, alpha > 0).
##' @param rate Scale parameter via rate (Beta, alpha > 0). Alternatively can
##' often also \code{scale} can be specified (\code{rate = 1/scale}).
##' @param ... arguments passed through to \code{\link{oclFunction}}
##' @return
##' \code{qinvgammaOCL} returns one
##' returns a numeric vector of the same length as the input.
##'
##' @details
##' The calculations are outsourced to the OpenCL hardware. In
##' Background, the compiler uses those implemented in the stable log space
##' C functions of the GPGPU library. The random number generation is done via
##' a parallelized Mersenne twister (MT19937) directly in the VRAM.
##'
##' @seealso \code{\link{GetActiveDeviceInfo}}
##' @export
qinvgammaOCL <- (function() {
  .qinvgamma_ocl_internal <- NULL
  function(p, shape, rate = 1, ...) {
    if (is.null(.qinvgamma_ocl_internal)) {
      .qinvgamma_ocl_internal <<- OpenCLeaR::oclFunction(
        signature = methods::signature(p = "numeric", shape = "numeric", rate = "numeric"),
        kernel_file = "qinvgamma.cl", interface_file = "qinvgamma.cpp", ...
      )
    }
    return(.qinvgamma_ocl_internal(p, shape, rate))
  }
})()

