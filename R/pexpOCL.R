if (getRversion() >= "2.15.1") {
    utils::globalVariables(".pexp_ocl_internal")
}
##' Distribution function for an exponential distribution via OpenCL
##'
##' @name pexpOCL
##' @param q     vector of quantiles.
##' @param rate  vector of rates (inverse scale).
##' @param ...   arguments passed through to \code{\link{oclFunction}}
##' @return A numeric vector of probabilities.
##' @export
pexpOCL <- (function() {
  .pexp_ocl_internal <- NULL
  function(q, rate = 1, ...) {
    if (is.null(.pexp_ocl_internal)) {
      .pexp_ocl_internal <<- OpenCLeaR::oclFunction(
        signature = methods::signature(q = "numeric", rate = "numeric"),
        kernel_file = "pexp.cl", interface_file = "pexp.cpp", ...
      )
    }
    return(.pexp_ocl_internal(q, rate))
  }
})()
