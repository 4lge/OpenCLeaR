if (getRversion() >= "2.15.1") {
  utils::globalVariables(".dmvnorm_ocl_internal")
}

##' Multivariate Normal Density Function (PDF) via OpenCL
##' 
##' @name dmvnormOCL
##' @param x      vector or matrix of quantiles (rows are observations, columns are dimensions).
##' @param mean   mean vector parameter (default: rep(0, ncol(x))).
##' @param sigma  covariance matrix parameter (default: diag(ncol(x))).
##' @param log    logical; if TRUE, probabilities p are given as log(p).
##' @param ...    arguments passed through to \code{\link{oclFunction}}
##' @return A numeric vector of densities of length nrow(x).
##' @export
dmvnormOCL <- (function() {
  .dmvnorm_ocl_internal <- NULL
  function(x, mean = NULL, sigma = NULL, log = FALSE, ...) {
    if (!is.matrix(x)) {
      x <- matrix(x, nrow = 1L)
    }
    dim <- ncol(x)
    if (is.null(mean))  mean  <- rep(0, dim)
    if (is.null(sigma)) sigma <- diag(dim)

    if (is.null(.dmvnorm_ocl_internal)) {
      .dmvnorm_ocl_internal <<- OpenCLeaR::oclFunction(
        signature = methods::signature(
          x     = "matrix", 
          mean  = "numeric", 
          sigma = "matrix", 
          log   = "logical"
        ),
        kernel_file = "dmvnorm.cl",    
        interface_file = "dmvnorm.cpp",
        ...
      )
    }
    return(.dmvnorm_ocl_internal(
      as.matrix(x), 
      as.numeric(mean), 
      as.matrix(sigma), 
      as.logical(log)
    ))
  }
})()
