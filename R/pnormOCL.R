if (getRversion() >= "2.15.1") {
    utils::globalVariables(".pnorm_ocl_internal")
}

##' Distribution function for a normal distribution via OpenCL
##' 
##' @name pnormOCL
##' @param q     vector of quantiles.
##' @param mean  mean parameter.
##' @param sd    standard deviation parameter.
##' @param ...   arguments passed through to \code{\link{oclFunction}}
##' @return A numeric vector of probabilities.
##' @export
pnormOCL <- (function() {
  .pnorm_ocl_internal <- NULL
  function(q, mean = 0, sd = 1, ...) {
    ##if (!OpenCLeaR::EnsureOpenCLInitialized()) {
    ##  return(stats::pnorm(q, mean, sd))
    ##}
    if (is.null(.pnorm_ocl_internal)) {
      .pnorm_ocl_internal <<- OpenCLeaR::oclFunction(
        signature = methods::signature(q = "numeric", mean = "numeric", sd = "numeric"),
        kernel_file = "pnorm.cl",    
        interface_file = "pnorm.cpp",
        ...
      )
    }
    return(.pnorm_ocl_internal(q, mean, sd))
  }
})()
