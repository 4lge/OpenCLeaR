# Wir teilen R mit, dass diese internen JIT-Objekte fliegend erzeugt werden!
if (getRversion() >= "2.15.1") {
  utils::globalVariables(".rgeom_ocl_internal")
}
##' Random number generation from a geometric distribution via OpenCL
##' 
##' @name rgeomOCL
##' @param n count of random numbers to generate.
##' @param prob probability of success in each trial.
##' @param ... arguments passed through to \code{\link{oclFunction}}
##' @return A vector of random numbers.
##' @note This function will not necessarily increase speed of computation.
##' @export
rgeomOCL <- (function() {
  
    ## Diese Variable bleibt über Lexical Scoping innerhalb der Closure geschützt
    .rgeom_ocl_internal <- NULL
    
    function(n, prob, ...) {
   
    ## Lazy Evaluation: Nur beim allerersten Aufruf kompilieren
    if (is.null(.rgeom_ocl_internal)) {
        .rgeom_ocl_internal <<- OpenCLeaR::oclFunction(
                                                signature      = methods::signature(n = "integer",
                                                                                    prob = "numeric"),
                                               kernel_file    = "rgeom.cl",
                                               interface_file = "rgeom.cpp",
                                               ...
                                           )
        }
        return(.rgeom_ocl_internal(as.integer(n), prob))
    }
})()

