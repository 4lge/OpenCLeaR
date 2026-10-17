# Wir teilen R mit, dass diese internen JIT-Objekte fliegend erzeugt werden!
if (getRversion() >= "2.15.1") {
  utils::globalVariables(".rbeta_ocl_internal")
}
##' Random number generation from a beta distribution via OpenCL
##' 
##' @name rbetaOCL
##' @param n count of random numbers to generate.
##' @param shape1 positive parameter of the Beta distribution.
##' @param shape2 positive parameter of the Beta distribution.
##' @param ... arguments passed through to \code{\link{oclFunction}}
##' @return A vector of random numbers.
##' @note This function will not necessarily increase speed of computation.
##' @export
rbetaOCL <- (function() {
  
    ## Diese Variable bleibt über Lexical Scoping innerhalb der Closure geschützt
    .rbeta_ocl_internal <- NULL
    
    function(n, shape1, shape2, ...) {
   
    ## Lazy Evaluation: Nur beim allerersten Aufruf kompilieren
    if (is.null(.rbeta_ocl_internal)) {
        .rbeta_ocl_internal <<- OpenCLeaR::oclFunction(
                                               signature      = methods::signature(n = "integer",
                                                                                   shape1 = "numeric",
                                                                                   shape2 = "numeric"),
                                               kernel_file    = "rbeta.cl",
                                               interface_file = "rbeta.cpp",
                                               ...
                                           )
    }
        return(.rbeta_ocl_internal(as.integer(n), shape1, shape2))
    }
})()
