if (getRversion() >= "2.15.1") {
    utils::globalVariables(".rinvgamma_ocl_internal")
}

##' Zufallszahlen der Inverse-Gamma-Verteilung via OpenCL
##'
##' @title Inverse-Gamma-Verteilung (OpenCL-beschleunigt)
##'
##' @description
##' Diese Funktion generiert Zufallszahlen (\code{rinvgammaOCL})
##' für die Inverse-Gamma-Verteilung auf dem aktiven GPGPU-Device.
##'
##' @param n Anzahl der zu generierenden Zufallszahlen.
##' @param shape Formparameter (Shape, alpha > 0).
##' @param rate Skalenparameter via Rate (Beta, alpha > 0). Alternativ kann
##'   oft auch \code{scale} spezifiziert werden (\code{rate = 1/scale}).
##' @param ...    arguments passed through to \code{\link{oclFunction}}
##' @return
##' \code{rinvgammaOCL} liefert einen numerischen Vektor der Länge \code{n}.
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
