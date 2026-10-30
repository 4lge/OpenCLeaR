if (getRversion() >= "2.15.1") {
    utils::globalVariables(c(".dinvgamma_ocl_internal", ".pinvgamma_ocl_internal", 
                             ".qinvgamma_ocl_internal", ".rinvgamma_ocl_internal"))
}

##' Dichte, Verteilung, Quantile und Zufallszahlen der Inverse-Gamma-Verteilung via OpenCL
##'
##' @title Inverse-Gamma-Verteilung (OpenCL-beschleunigt)
##'
##' @description
##' Diese Funktionen berechnen die Dichte (\code{dinvgammaOCL}), die
##' kumulierte Verteilungsfunktion (\code{pinvgammaOCL}), die Quantilfunktion
##' (\code{qinvgammaOCL}) und generieren Zufallszahlen (\code{rinvgammaOCL})
##' für die Inverse-Gamma-Verteilung auf dem aktiven GPGPU-Device.
##'
##' @param x,q Vektor von Quantilen (Eingabe-Grenzwerte).
##' @param p Vektor von Wahrscheinlichkeiten.
##' @param n Anzahl der zu generierenden Zufallszahlen.
##' @param shape Formparameter (Shape, alpha > 0).
##' @param rate Skalenparameter via Rate (Beta, alpha > 0). Alternativ kann
##'   oft auch \code{scale} spezifiziert werden (\code{rate = 1/scale}).
##' @param device An optionales OpenCL-Device-Objekt. Falls nicht angegeben,
##'   wird das global aktive Standard-Device verwendet.
##'
##' @return
##' \code{dinvgammaOCL}, \code{pinvgammaOCL} und \code{qinvgammaOCL} geben einen
##' numerischen Vektor der gleichen Länge wie die Eingabe zurück.
##' \code{rinvgammaOCL} liefert einen numerischen Vektor der Länge \code{n}.
##'
##' @details
##' Die Berechnungen werden bitscharf auf die Hardware ausgelagert. Im
##' Hintergrund nutzt der Compiler die im stabilen Log-Raum implementierten
##' C-Funktionen der GPGPU-Library. Die Zufallszahlen-Generierung erfolgt über
##' einen parallelisierten Mersenne-Twister (MT19937) direkt im VRAM.
##'
##' @seealso \code{\link{GetActiveDeviceInfo}}
##'
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

#' @export
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

#' @export
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

#' @export
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
