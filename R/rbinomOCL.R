# Wir teilen R mit, dass diese internen JIT-Objekte fliegend erzeugt werden!
if (getRversion() >= "2.15.1") {
  utils::globalVariables(".rbinom_ocl_internal")
}
##' Random number generation from a binomial distribution via OpenCL
##' 
##' @name rbinomOCL
##' @param n count of random numbers to generate.
##' @param size number of trials (zero or more).
##' @param prob probability of success on each trial.
##' @param ... arguments passed through to \code{\link{oclFunction}}
##' @return A vector of random numbers.
##' @note This function will not necessarily increase speed of computation.
##' @export
rbinomOCL <-  (function() {
  
    ## Diese Variable bleibt über Lexical Scoping innerhalb der Closure geschützt
    .rbinom_ocl_internal <- NULL
    
    function(n, size, prob, ...) {
        ## Lazy Evaluation: Nur beim allerersten Aufruf kompilieren
        if (is.null(.rbinom_ocl_internal)) {
            .rbinom_ocl_internal <<- OpenCLeaR::oclFunction(
                                                    signature      = methods::signature(n = "integer",
                                                                                        size = "integer",
                                                                                        prob = "numeric"),
                                                    kernel_file    = "rbinom.cl",
                                                    interface_file = "rbinom.cpp",
                                                    ...
                                                )
        }
        return(.rbinom_ocl_internal(as.integer(n), as.integer(size), prob, ...))
    }
})()
