.extract_rng_kind <- function(...) {
  dots <- list(...)
  if ("RNGkind" %in% names(dots)) {
    rk <- match.arg(dots$RNGkind, c("Mersenne-Twister", "Xorshift128"))
  } else {
    rk <- "Mersenne-Twister"
  }
  list(RNGkind = rk, dots = dots)
}

