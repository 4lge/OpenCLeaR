if (getRversion() >= "2.15.1") {
    utils::globalVariables(".pgeom_ocl_internal")
}
##' Distribution function for a geometric distribution via OpenCL
##'
##' @name pgeomOCL
##' @param q     vector of quantiles.
##' @param prob  probability of success in each trial. 0 < prob <= 1.
##' @param ...   arguments passed through to \code{\link{oclFunction}}
##' @return A numeric vector of probabilities.
##' @export
pgeomOCL <- (function() {
  .pgeom_ocl_internal <- NULL
  function(q, prob, ...) {
    if (is.null(.pgeom_ocl_internal)) {
      .pgeom_ocl_internal <<- OpenCLeaR::oclFunction(
        signature = methods::signature(q = "numeric", prob = "numeric"),
        kernel_file = "pgeom.cl", interface_file = "pgeom.cpp", ...
      )
    }
    return(.pgeom_ocl_internal(q, prob))
  }
})()
