# Wir teilen R mit, dass diese internen JIT-Objekte fliegend erzeugt werden!
if (getRversion() >= "2.15.1") {
  utils::globalVariables(".rpois_ocl_internal")
}
##' Random number generation from a poisson distribution via OpenCL
##' 
##' @name rpoisOCL
##' @param n count of random numbers to generate.
##' @param lambda vector of (non-negative) means.
##' @param ... arguments passed through to \code{\link{oclFunction}}
##' @return A vector of random numbers.
##' @note This function will not necessarily increase speed of computation.
##' @export
rpoisOCL <- (function() {
  
    ## Diese Variable bleibt über Lexical Scoping innerhalb der Closure geschützt
    .rpois_ocl_internal <- NULL
    
    function(n, lambda, ...) {
   
    ## Lazy Evaluation: Nur beim allerersten Aufruf kompilieren
    if (is.null(.rpois_ocl_internal)) {
        .rpois_ocl_internal <<- OpenCLeaR::oclFunction(
                                               signature      = methods::signature(n = "integer",
                                                                                   lambda = "numeric"),
                                               kernel_file    = "rpois.cl",
                                               interface_file = "rpois.cpp",
                                               ...
                                           )
    }
        return(.rpois_ocl_internal(as.integer(n), lambda))
    }
})()
