if (getRversion() >= "2.15.1") {
  utils::globalVariables(".pmvnorm_ocl_internal")
}

##' Multivariate Normal Distribution Function (CDF) via GPU Monte Carlo
##' 
##' @name pmvnormOCL
##' @param lower   vector of lower integration limits (length dim, can contain -Inf).
##' @param upper   vector of upper integration limits (length dim, can contain Inf).
##' @param mean    mean vector parameter (default: rep(0, length(lower))).
##' @param sigma   covariance matrix parameter (default: diag(length(lower))). Maximimum dimension supported: 64 times 64.
##' @param n       number of Monte Carlo samples (default: 1e6).
##' @param ...     arguments passed through to \code{\link{oclFunction}}
##' @return Estimated probability with attributes \code{error} (MC standard error) and \code{samples}.
##' @export
pmvnormOCL <- (function() {
  .pmvnorm_ocl_internal <- NULL
  function(lower = rep(-Inf, length(upper)), 
           upper = rep(Inf, length(lower)), 
           mean = rep(0, length(lower)), 
           sigma = diag(length(lower)), 
           n = 1e6L, ...) {
    
    if (is.null(.pmvnorm_ocl_internal)) {
      .pmvnorm_ocl_internal <<- OpenCLeaR::oclFunction(
        signature = methods::signature(
          lower = "numeric", 
          upper = "numeric", 
          mean  = "numeric", 
          sigma = "matrix", 
          n     = "integer"
        ),
        kernel_file = "pmvnorm.cl",    
        interface_file = "pmvnorm.cpp",
        ...
      )
    }
    return(.pmvnorm_ocl_internal(
      as.numeric(lower), 
      as.numeric(upper), 
      as.numeric(mean), 
      as.matrix(sigma), 
      as.integer(n)
    ))
  }
})()
