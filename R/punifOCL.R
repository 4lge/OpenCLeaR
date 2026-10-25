if (getRversion() >= "2.15.1") {
    utils::globalVariables(".punif_ocl_internal")
}
##' Distribution function for a uniform distribution via OpenCL
##'
##' @name punifOCL
##' @param q    vector of quantiles.
##' @param min  lower limit of the distribution.
##' @param max  upper limit of the distribution.
##' @param ...  arguments passed through to \code{\link{oclFunction}}
##' @return A numeric vector of probabilities.
##' @export
punifOCL <- (function() {
  .punif_ocl_internal <- NULL
  function(q, min = 0, max = 1, ...) {
    if (is.null(.punif_ocl_internal)) {
      .punif_ocl_internal <<- OpenCLeaR::oclFunction(
        signature = methods::signature(q = "numeric", min = "numeric", max = "numeric"),
        kernel_file = "punif.cl",
        interface_file = "punif.cpp",
        ...
      )
    }
    return(.punif_ocl_internal(q, min, max))
  }
})()
