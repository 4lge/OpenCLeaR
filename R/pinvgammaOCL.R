if (getRversion() >= "2.15.1") {
    utils::globalVariables(".pinvgamma_ocl_internal")
}

##' Verteilung der Inverse-Gamma-Verteilung via OpenCL
##'
##' @title Inverse-Gamma-Verteilung (OpenCL-beschleunigt)
##'
##' @description
##' Diese Funktion berechnt die kumulierte Verteilungsfunktion
##' für die Inverse-Gamma-Verteilung auf dem aktiven GPGPU-Device.
##'
##' @param q Vektor von Quantilen (Eingabe-Grenzwerte).
##' @param shape Formparameter (Shape, alpha > 0).
##' @param rate Skalenparameter via Rate (Beta, alpha > 0). Alternativ kann
##'   oft auch \code{scale} spezifiziert werden (\code{rate = 1/scale}).
##' @param ...    arguments passed through to \code{\link{oclFunction}}
##' @return
##' \code{pinvgammaOCL}  gibt einen
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

