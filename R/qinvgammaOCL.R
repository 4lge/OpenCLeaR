if (getRversion() >= "2.15.1") {
    utils::globalVariables(".qinvgamma_ocl_internal")
}

##' Quantile der Inverse-Gamma-Verteilung via OpenCL
##'
##' @title Inverse-Gamma-Verteilung (OpenCL-beschleunigt)
##'
##' @description
##' Diese Funktion berechnet die Quantilfunktion
##' (\code{qinvgammaOCL})
##' für die Inverse-Gamma-Verteilung auf dem aktiven GPGPU-Device.
##'
##' @param p Vektor von Wahrscheinlichkeiten.
##' @param shape Formparameter (Shape, alpha > 0).
##' @param rate Skalenparameter via Rate (Beta, alpha > 0). Alternativ kann
##'   oft auch \code{scale} spezifiziert werden (\code{rate = 1/scale}).
##' @param ...    arguments passed through to \code{\link{oclFunction}}
##' @return
##' \code{qinvgammaOCL} gibt einen
##' numerischen Vektor der gleichen Länge wie die Eingabe zurück.
##'
##' @details
##' Die Berechnungen werden auf die OpenCL Hardware ausgelagert. Im
##' Hintergrund nutzt der Compiler die im stabilen Log-Raum implementierten
##' C-Funktionen der GPGPU-Library. Die Zufallszahlen-Generierung erfolgt über
##' einen parallelisierten Mersenne-Twister (MT19937) direkt im VRAM.
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

