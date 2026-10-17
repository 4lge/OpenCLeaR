# Wir teilen R mit, dass diese internen JIT-Objekte fliegend erzeugt werden!
if (getRversion() >= "2.15.1") {
  utils::globalVariables(".rexp_ocl_internal")
}
##' Random number generation from an exponential distribution via OpenCL
##' 
##' @name rexpOCL
##' @param n count of random numbers to generate.
##' @param rate vector of rates.
##' @param ... arguments passed through to \code{\link{oclFunction}}
##' @return A vector of random numbers.
##' @note This function will not necessarily increase speed of computation.
##' @export
rexpOCL <-  (function() {
  
    ## Diese Variable bleibt über Lexical Scoping innerhalb der Closure geschützt
    .rexp_ocl_internal <- NULL
    
    function(n, rate = 1, ...) {
        
           ## Lazy Evaluation: Nur beim allerersten Aufruf kompilieren
        if (is.null(.rexp_ocl_internal)) {
        .rexp_ocl_internal <<- OpenCLeaR::oclFunction(
                                              signature      = methods::signature(n = "integer",
                                                                                  rate = "numeric"),
                                              kernel_file    = "rexp.cl",
                                              interface_file = "rexp.cpp",
                                              ...
                                          )
        }
        return(.rexp_ocl_internal(as.integer(n), rate))
    }
})()
