if (getRversion() >= "2.15.1") {
    utils::globalVariables(".dnorm_ocl_internal")
}
##' Density calculation for a normal distribution via OpenCL
##' 
##' @name dnormOCL
##' @param x     vector of quantiles.
##' @param mean  mean parameter.
##' @param sd    standard deviation parameter.
##' @param ...   arguments passed through to \code{\link{oclFunction}}
##' @return A numeric vector of densities.
##' @export
dnormOCL <- (function() {
  .dnorm_ocl_internal <- NULL
  function(x, mean = 0, sd = 1, ...) {
    ##if (!OpenCLeaR::EnsureOpenclInitialized()) {
    ##  return(stats::dnorm(x, mean, sd))
    ##}
    if (is.null(.dnorm_ocl_internal)) {
      .dnorm_ocl_internal <<- OpenCLeaR::oclFunction(
        signature = methods::signature(x = "numeric", mean = "numeric", sd = "numeric"),
        kernel_file = "dnorm.cl",    
        interface_file = "dnorm.cpp",
        ...
      )
    }
    return(.dnorm_ocl_internal(x, mean, sd))
  }
})()
