if (getRversion() >= "2.15.1") {
  utils::globalVariables(".qmvnorm_ocl_internal")
}

##' Equicoordinate Quantiles of the Multivariate Normal Distribution via OpenCL
##' 
##' Computes equicoordinate quantiles of the multivariate normal distribution 
##' directly on the OpenCL device using Monte Carlo integration and bisection.
##' 
##' @name qmvnormOCL
##' @param p      probability level (0 <= p <= 1).
##' @param tail   specifies which quantiles should be computed: 
##'               \code{"lower.tail"} (gives \eqn{q} such that \eqn{P(X \le \mu + q) = p}), 
##'               \code{"upper.tail"} (gives \eqn{q} such that \eqn{P(X \ge \mu - q) = p}), or 
##'               \code{"both.tails"} (gives \eqn{q} such that \eqn{P(|X - \mu| \le q) = p}).
##' @param mean   mean vector parameter (default: 0).
##' @param sigma  covariance matrix parameter (default: 1).
##' @param n      total number of Monte Carlo samples across device threads (default: 1e6).
##' @param ...    arguments passed through to \code{\link{oclFunction}}
##' @return A numeric scalar representing the estimated equicoordinate quantile.
##' @export
qmvnormOCL <- (function() {
  .qmvnorm_ocl_internal <- NULL
  function(p, tail = c("lower.tail", "upper.tail", "both.tails"),
           mean = 0, sigma = 1, n = 1e6L, ...) {
    tail <- match.arg(tail)
    if (length(mean) == 1L && is.matrix(sigma) && nrow(sigma) > 1L) {
      mean <- rep(mean, nrow(sigma))
    }
    sigma <- as.matrix(sigma)

    if (is.null(.qmvnorm_ocl_internal)) {
      .qmvnorm_ocl_internal <<- OpenCLeaR::oclFunction(
        signature = methods::signature(
          p     = "numeric",
          mean  = "numeric",
          sigma = "matrix",
          tail  = "character",
          n     = "integer"
        ),
        kernel_file = "qmvnorm.cl",
        interface_file = "qmvnorm.cpp",
        ...
      )
    }
    return(.qmvnorm_ocl_internal(
      as.numeric(p),
      as.numeric(mean),
      sigma,
      as.character(tail),
      as.integer(n)
    ))
  }
})()
