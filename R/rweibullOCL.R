if (getRversion() >= "2.15.1") {
    utils::globalVariables(".rweibull_ocl_internal")
}
##' Random number generation from a Weibull distribution via OpenCL
##'
##' @name rweibullOCL
##' @param n      count of random numbers to generate.
##' @param shape  shape parameter (must be positive).
##' @param scale  scale parameter (must be positive, defaults to 1).
##' @param ...    arguments passed through to \code{\link{oclFunction}}
##' @return A vector of random numbers.
##' @export
rweibullOCL <- (function() {
  .rweibull_ocl_internal <- NULL
  last_RNGkind <- NULL

  function(n, shape, scale = 1, ...) {
    parsed <- .extract_rng_kind(...)
    if (is.null(.rweibull_ocl_internal) || !identical(last_RNGkind, parsed$RNGkind)) {
      .rweibull_ocl_internal <<- OpenCLeaR::oclFunction(
        signature = methods::signature(n = "integer", shape = "numeric", scale = "numeric"),
        kernel_file = "rweibull.cl", interface_file = "rweibull.cpp", ...
      )
      last_RNGkind <<- parsed$RNGkind
    }
    return(.rweibull_ocl_internal(n, shape, scale))
  }
})()
