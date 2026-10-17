# Wir teilen R mit, dass diese internen JIT-Objekte fliegend erzeugt werden!
if (getRversion() >= "2.15.1") {
  utils::globalVariables(".rt_ocl_internal")
}
##' Random number generation from a t distribution via OpenCL
##' 
##' @name rtOCL
##' @param n count of random numbers to generate.
##' @param df degrees of freedom (non-negative, but can be non-integer).
##' @param ... arguments passed through to \code{\link{oclFunction}}
##' @return A vector of random numbers.
##' @note This function will not necessarily increase speed of computation.
##' @export
rtOCL <- (function() {
  
    ## Diese Variable bleibt über Lexical Scoping innerhalb der Closure geschützt
    .rt_ocl_internal <- NULL
    
    function(n, df, ...) {
   
    ## Lazy Evaluation: Nur beim allerersten Aufruf kompilieren
    if (is.null(.rt_ocl_internal)) {
        .rt_ocl_internal <<- OpenCLeaR::oclFunction(
                                               signature      = methods::signature(n = "integer",
                                                                                   df = "integer"),
                                               kernel_file    = "rt.cl",
                                               interface_file = "rt.cpp",
                                               ...
                                           )
        }
        return(.rt_ocl_internal(as.integer(n), as.integer(df)))
    }
})()
