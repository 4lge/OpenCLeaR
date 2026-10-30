# We tell R that these internal JIT objects will be created on the fly!
if (getRversion() >= "2.15.1") {
  utils::globalVariables(".rnorm_ocl_internal")
}
##' Random number generation from a normal distribution via OpenCL
##' 
##' @name rnormOCL
##' @param n      count of random numbers to generate.
##' @param mean   mean parameter.
##' @param sd     standard deviation parameter.
##' @param ...    arguments passed through to \code{\link{oclFunction}}
##' @return A vector of random numbers.
##' @export
rnormOCL <- (function() {
  .rnorm_ocl_internal <- NULL
  function(n, mean = 0, sd = 1, ...) {
    if (is.null(.rnorm_ocl_internal)) {
      .rnorm_ocl_internal <<- OpenCLeaR::oclFunction(
        signature = methods::signature(n = "integer", mean = "numeric", sd = "numeric"),
          kernel_file = "rnorm.cl",    
          interface_file = "rnorm.cpp",
        ...
      )
    }
    return(.rnorm_ocl_internal(n, mean, sd))
  }
})()
