if (getRversion() >= "2.15.1") {
    utils::globalVariables(".qnorm_ocl_internal")
}

##' Quantile function for a normal distribution via OpenCL
##' 
##' @name qnormOCL
##' @param p     vector of probabilities.
##' @param mean  mean parameter.
##' @param sd    standard deviation parameter.
##' @param ...   arguments passed through to \code{\link{oclFunction}}
##' @return A numeric vector of quantiles.
##' @export
qnormOCL <- (function() {
  .qnorm_ocl_internal <- NULL
  function(p, mean = 0, sd = 1, ...) {
    ##if (!OpenCLeaR::EnsureOpenCLInitialized()) {
    ##  return(stats::qnorm(p, mean, sd))
    ##}
    if (is.null(.qnorm_ocl_internal)) {
      .qnorm_ocl_internal <<- OpenCLeaR::oclFunction(
        signature = methods::signature(p = "numeric", mean = "numeric", sd = "numeric"),
        kernel_file = "qnorm.cl",    
        interface_file = "qnorm.cpp",
        ...
      )
    }
    return(.qnorm_ocl_internal(p, mean, sd))
  }
})()
