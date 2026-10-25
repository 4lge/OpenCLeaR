if (getRversion() >= "2.15.1") {
    utils::globalVariables(".rexp_ocl_internal")
}
##' Random number generation from an exponential distribution via OpenCL
##'
##' @name rexpOCL
##' @param n     count of random numbers to generate.
##' @param rate  vector of rates (inverse scale).
##' @param ...   arguments passed through to \code{\link{oclFunction}}
##' @return A vector of random numbers.
##' @export
rexpOCL <- (function() {
  .rexp_ocl_internal <- NULL
  function(n, rate = 1, ...) {
    if (is.null(.rexp_ocl_internal)) {
      .rexp_ocl_internal <<- OpenCLeaR::oclFunction(
        signature = methods::signature(n = "integer", rate = "numeric"),
        kernel_file = "rexp.cl", interface_file = "rexp.cpp", ...
      )
    }
    return(.rexp_ocl_internal(n, rate))
  }
})()
