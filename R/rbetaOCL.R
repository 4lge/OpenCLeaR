if (getRversion() >= "2.15.1") {
    utils::globalVariables(".rbeta_ocl_internal")
}
##' Random number generation from a beta distribution via OpenCL
##'
##' @name rbetaOCL
##' @param n       count of random numbers to generate.
##' @param shape1  non-negative parameter of the Beta distribution.
##' @param shape2  non-negative parameter of the Beta distribution.
##' @param ...     arguments passed through to \code{\link{oclFunction}}
##' @return A vector of random numbers.
##' @export
rbetaOCL <- (function() {
  .rbeta_ocl_internal <- NULL
  last_RNGkind <- NULL

  function(n, shape1, shape2, ...) {
    parsed <- .extract_rng_kind(...)
    if (is.null(.rbeta_ocl_internal) || !identical(last_RNGkind, parsed$RNGkind)) {
      .rbeta_ocl_internal <<- OpenCLeaR::oclFunction(
        signature = methods::signature(n = "integer", shape1 = "numeric", shape2 = "numeric"),
        kernel_file = "rbeta.cl", interface_file = "rbeta.cpp", ...
      )
      last_RNGkind <<- parsed$RNGkind
    }
    return(.rbeta_ocl_internal(n, shape1, shape2))
  }
})()
