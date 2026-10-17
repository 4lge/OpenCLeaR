# Wir teilen R mit, dass diese internen JIT-Objekte fliegend erzeugt werden!
if (getRversion() >= "2.15.1") {
  utils::globalVariables(".rnbinom_ocl_internal")
}
##' Random number generation from a negative binomial distribution via OpenCL
##' 
##' @name rnbinomOCL
##' @param n count of random numbers to generate.
##' @param size target for number of successful trials, or dispersion parameter.
##' @param prob probability of success in each trial.
##' @param mu alternative parametrization via mean.
##' @param ... arguments passed through to \code{\link{oclFunction}}
##' @return A vector of random numbers.
##' @note This function will not necessarily increase speed of computation.
##' @export
rnbinomOCL <- (function() {
  
    ## Diese Variable bleibt über Lexical Scoping innerhalb der Closure geschützt
    .rnbinom_ocl_internal <- NULL
    
    function(n, size, prob, mu, ...) {
   
    ## Lazy Evaluation: Nur beim allerersten Aufruf kompilieren
    if (is.null(.rnbinom_ocl_internal)) {
        .rnbinom_ocl_internal <<- OpenCLeaR::oclFunction(
                                                 signature      = methods::signature(n = "integer",
                                                                                     size = "integer",
                                                                                     prob = "numeric", mu = "numeric"),
                                                 kernel_file    = "rnbinom.cl",
                                                 interface_file = "rnbinom.cpp",
                                                 ...
                                             )
        }
        return(.rnbinom_ocl_internal(as.integer(n), as.integer(size), prob, mu))
    }
})()
