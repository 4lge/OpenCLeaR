if (getRversion() >= "2.15.1") {
    utils::globalVariables(".rgeom_ocl_internal")
}
##' Random number generation from a geometric distribution via OpenCL
##'
##' @name rgeomOCL
##' @param n     count of random numbers to generate.
##' @param prob  probability of success in each trial. 0 < prob <= 1.
##' @param ...   arguments passed through to \code{\link{oclFunction}}
##' @return A vector of random numbers.
##' @export
rgeomOCL <- (function() {
  .rgeom_ocl_internal <- NULL
  last_RNGkind <- NULL

  function(n, prob, ...) {
    parsed <- .extract_rng_kind(...)
    if (is.null(.rgeom_ocl_internal) || !identical(last_RNGkind, parsed$RNGkind)) {
      .rgeom_ocl_internal <<- OpenCLeaR::oclFunction(
        signature = methods::signature(n = "integer", prob = "numeric"),
        kernel_file = "rgeom.cl", interface_file = "rgeom.cpp", ...
      )
      last_RNGkind <<- parsed$RNGkind
    }
    return(.rgeom_ocl_internal(n, prob))
  }
})()
