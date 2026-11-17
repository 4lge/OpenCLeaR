if (getRversion() >= "2.15.1") {
  utils::globalVariables(".rmvnorm_ocl_internal")
}
##' Random number generation from a multivariate normal distribution via OpenCL
##' 
##' @name rmvnormOCL
##' @param n      count of random vectors to generate.
##' @param mean   mean vector parameter.
##' @param sigma  covariance matrix parameter.
##' @param ...    arguments passed through to \code{\link{oclFunction}}
##' @return A matrix of random vectors (n x length(mean)).
##' @export
rmvnormOCL <- (function() {
  .rmvnorm_ocl_internal <- NULL
  function(n, mean, sigma, ...) {
    if (is.null(.rmvnorm_ocl_internal)) {
      .rmvnorm_ocl_internal <<- OpenCLeaR::oclFunction(
        signature = methods::signature(n = "integer", mean = "numeric", sigma = "matrix"),
        kernel_file = "rmvnorm.cl",    
        interface_file = "rmvnorm.cpp",
        ...
      )
    }
    return(.rmvnorm_ocl_internal(as.integer(n), as.numeric(mean), as.matrix(sigma)))
  }
})()
