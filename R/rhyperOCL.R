# Wir teilen R mit, dass diese internen JIT-Objekte fliegend erzeugt werden!
if (getRversion() >= "2.15.1") {
  utils::globalVariables(".rhyper_ocl_internal")
}
##' Random number generation from a hyoergeometric distribution via OpenCL
##' 
##' @name rhyperOCL
##' @param nn number of observations.
##' @param m the number of white balls in the urn.
##' @param n the number of black balls in the urn.
##' @param k the number of balls drawn from the urn.
##' @param ... arguments passed through to \code{\link{oclFunction}}
##' @return A vector of random numbers.
##' @note This function will not necessarily increase speed of computation.
##' @export
rhyperOCL <- (function() {
  
    ## Diese Variable bleibt über Lexical Scoping innerhalb der Closure geschützt
    .rhyper_ocl_internal <- NULL
    
    function(nn, m, n, k, ...) {
   
    ## Lazy Evaluation: Nur beim allerersten Aufruf kompilieren
    if (is.null(.rhyper_ocl_internal)) {
        .rhyper_ocl_internal <<-  OpenCLeaR::oclFunction(
                                                 signature      = methods::signature(nn = "integer",
                                                                                     m = "integer",
                                                                                     n = "integer",
                                                                                     k = "integer"),
                                                 kernel_file    = "rhyper.cl",
                                                 interface_file = "rhyper.cpp",
                                                 ...
                                             )
    }
        return(.rhyper_ocl_internal(as.integer(nn), as.integer(m), as.integer(n), as.integer(k)))
    }
})()
