# Wir teilen R mit, dass diese internen JIT-Objekte fliegend erzeugt werden!
if (getRversion() >= "2.15.1") {
  utils::globalVariables(".runif_ocl_internal")
}

##' Random number generation from a uniform distribution via OpenCL
##' 
##' @name runifOCL
##' @param n    count of random numbers to generate.
##' @param min lower boundary parameter.
##' @param max upper boundary parameter.
##' @param ... arguments passed through to \code{\link{oclFunction}} like \code{verbose} or \code{force_float}
##' @return A vector of random numbers.
##' @note This function will not necessarily increase speed of
##'   computation, it is mainly intended for checking the OpenCL runif
##'   kernel and to compare its output to R's runif function!
##' @export
runifOCL <- (function() {
  
  ## Diese Variable bleibt über Lexical Scoping innerhalb der Closure geschützt
  .runif_ocl_internal <- NULL
  
  ## Das ist die eigentliche R-Funktion, die exportiert wird
  function(n, min = 0, max = 1, ...) {
    
    ## Lazy Evaluation: Nur beim allerersten Aufruf kompilieren
    if (is.null(.runif_ocl_internal)) {
      .runif_ocl_internal <<- OpenCLeaR::oclFunction(
        signature = signature(n = "integer", 
                              min = "numeric",
                              max = "numeric"),
        kernel_file = "runif.cl",
        interface_file = "runif.cpp",
        ...
        )
    }
    
    ## Wichtig: Argumente direkt durchreichen!
    return(.runif_ocl_internal(as.integer(n), min, max))
  }
})()
