if (getRversion() >= "2.15.1") {
    utils::globalVariables(".rt_ocl_internal")
}
##' Random number generation from a Student-t distribution via OpenCL
##'
##' @name rtOCL
##' @param n   count of random numbers to generate.
##' @param df  degrees of freedom (infinitely positive, or large).
##' @param ... arguments passed through to \code{\link{oclFunction}}
##' @return A vector of random numbers.
##' @export
rtOCL <- (function() {
  .rt_ocl_internal <- NULL
  last_RNGkind <- NULL

  function(n, df, ...) {
    parsed <- .extract_rng_kind(...)
    if (is.null(.rt_ocl_internal) || !identical(last_RNGkind, parsed$RNGkind)) {
      .rt_ocl_internal <<- OpenCLeaR::oclFunction(
        signature = methods::signature(n = "integer", df = "integer"),
        kernel_file = "rt.cl", interface_file = "rt.cpp", ...
      )
      last_RNGkind <<- parsed$RNGkind
    }
    return(.rt_ocl_internal(n, df))
  }
})()
