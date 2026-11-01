if (getRversion() >= "2.15.1") {
    utils::globalVariables(".dinvgamma_ocl_internal")
}

##' Dichte der Inverse-Gamma-Verteilung via OpenCL
##'
##' @title Inverse-Gamma-Verteilung (OpenCL-beschleunigt)
##'
##' @description
##' Diese Funktion berechnet die Dichte für die Inverse-Gamma-Verteilung auf dem aktiven GPGPU-Device.
##'
##' @param x Vektor von Quantilen (Eingabe-Grenzwerte).
##' @param shape Formparameter (Shape, alpha > 0).
##' @param rate Skalenparameter via Rate (Beta, alpha > 0). Alternativ kann
##'   oft auch \code{scale} spezifiziert werden (\code{rate = 1/scale}).
##' @param ...    arguments passed through to \code{\link{oclFunction}}
##' @return
##' \code{dinvgammaOCL} gibt einen
##' numerischen Vektor der gleichen Länge wie die Eingabe zurück.
##'
##' @details
##' Die Berechnungen werden auf die OpenCL Hardware ausgelagert. Im
##' Hintergrund nutzt der Compiler die im stabilen Log-Raum implementierten
##' C-Funktionen der GPGPU-Library. Die Zufallszahlen-Generierung erfolgt über
##' einen parallelisierten Mersenne-Twister (MT19937) direkt im VRAM.
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

