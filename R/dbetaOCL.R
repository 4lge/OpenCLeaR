if (getRversion() >= "2.15.1") {
    utils::globalVariables(".dbeta_ocl_internal")
}
##' Density calculation for a beta distribution via OpenCL
##'
##' @name dbetaOCL
##' @param x       vector of quantiles.
##' @param shape1  non-negative parameter of the Beta distribution.
##' @param shape2  non-negative parameter of the Beta distribution.
##' @param ...     arguments passed through to \code{\link{oclFunction}}
##' @return A numeric vector of densities.
##' @export
dbetaOCL <- (function() {
  .dbeta_ocl_internal <- NULL
  function(x, shape1, shape2, ...) {
    if (is.null(.dbeta_ocl_internal)) {
      .dbeta_ocl_internal <<- OpenCLeaR::oclFunction(
        signature = methods::signature(x = "numeric", shape1 = "numeric", shape2 = "numeric"),
        kernel_file = "dbeta.cl", interface_file = "dbeta.cpp", ...
      )
    }
    return(.dbeta_ocl_internal(x, shape1, shape2))
  }
})()
