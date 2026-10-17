# Wir teilen R mit, dass diese internen JIT-Objekte fliegend erzeugt werden!
if (getRversion() >= "2.15.1") {
  utils::globalVariables(".rgamma_ocl_internal")
}
##' Random number generation from a gamma distribution via OpenCL
##' 
##' @name rgammaOCL
##' @param n count of random numbers to generate.
##' @param shape shape parameter.
##' @param rate alternative way to specify the scale.
##' @param ... arguments passed through to \code{\link{oclFunction}}
##' @return A vector of random numbers.
##' @note This function will not necessarily increase speed of computation.
##' @export
rgammaOCL <-  (function() {
  
    ## Diese Variable bleibt über Lexical Scoping innerhalb der Closure geschützt
    .rgamma_ocl_internal <- NULL
    
    function(n, shape, rate = 1.0, ...) {
   
       ## Lazy Evaluation: Nur beim allerersten Aufruf kompilieren
    if (is.null(.rgamma_ocl_internal)) {
        .rgamma_ocl_internal <<- OpenCLeaR::oclFunction(
                                                signature      = methods::signature(n = "integer",
                                                                                    shape = "numeric",
                                                                                    rate = "numeric"),
                                                kernel_file    = "rgamma.cl",
                                                interface_file = "rgamma.cpp",
                                                ...
                                            )
    }
        return(.rgamma_ocl_internal(as.integer(n), shape, rate))
    }
})()
