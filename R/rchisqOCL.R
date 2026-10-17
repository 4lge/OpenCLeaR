# Wir teilen R mit, dass diese internen JIT-Objekte fliegend erzeugt werden!
if (getRversion() >= "2.15.1") {
  utils::globalVariables(".rchisq_ocl_internal")
}

##' Random number generation from a chisquare distribution via OpenCL
##' 
##' @name rchisqOCL
##' @param n count of random numbers to generate.
##' @param df degrees of freedom (non-negative, but can be non-integer).
##' @param ... arguments passed through to \code{\link{oclFunction}}
##' @return A vector of random numbers.
##' @note This function will not necessarily increase speed of computation.
##' @export
rchisqOCL <-  (function() {
  
    ## Diese Variable bleibt über Lexical Scoping innerhalb der Closure geschützt
    .rchisq_ocl_internal <- NULL

    function(n, df, ...) {
 
    ## Lazy Evaluation: Nur beim allerersten Aufruf kompilieren
    if (is.null(.rchisq_ocl_internal)) {
        .rchisq_ocl_internal <<-  OpenCLeaR::oclFunction(
                                                 signature      = methods::signature(n = "integer",
                                                                                     df = "integer"),
                                                 kernel_file    = "rchisq.cl",
                                                 interface_file = "rchisq.cpp",
                                                 ...
                                             )
        }
        return(.rchisq_ocl_internal(as.integer(n), as.integer(df)))
        }
})()
