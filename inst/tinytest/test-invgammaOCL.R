source("setup.R", local = TRUE)
if (!isTRUE(getOption("OpenCLeaR.initialized"))) exit_file("no OpenCL device available")

set.seed(1234)
p_vals <- seq(0.01, 0.99, length.out = 50)
sh <- 3.5
rt <- 2.1

# Referenz-Funktionen über R-Base Gamma Verknüpfungen
R_dinvgamma <- function(x, shape, rate) { exp(shape*log(rate) - lgamma(shape) - (shape+1)*log(x) - (rate/x)) }
R_pinvgamma <- function(q, shape, rate) { 1.0 - stats::pgamma(1.0/q, shape = shape, rate = rate) }
R_qinvgamma <- function(p, shape, rate) { 1.0 / stats::qgamma(1.0 - p, shape = shape, rate = rate) }

# Tests für d/p/q
expect_equal(dinvgammaOCL(p_vals, sh, rt), R_dinvgamma(p_vals, sh, rt), tolerance = 1e-4)
max_diff_d <- max(abs(ocl_d - ref_d), na.rm = TRUE)
message(sprintf("📊 [Test-Profil] dinvgammaOCL max abs diff: %.6e", max_diff_d))
expect_equal(pinvgammaOCL(p_vals, sh, rt), R_pinvgamma(p_vals, sh, rt), tolerance = 1e-4)
max_diff_p <- max(abs(ocl_p - ref_p), na.rm = TRUE)
message(sprintf("📊 [Test-Profil] pinvgammaOCL max abs diff: %.6e", max_diff_p))

expect_equal(qinvgammaOCL(p_vals, sh, rt), R_qinvgamma(p_vals, sh, rt), tolerance = 1e-4)
max_diff_q <- max(abs(ocl_q - ref_q), na.rm = TRUE)
message(sprintf("📊 [Test-Profil] qinvgammaOCL max abs diff: %.6e", max_diff_q))


# RNG KS-Test
ref_sim <- 1.0 / stats::rgamma(100, shape = sh, rate = rt)
ocl_sim <- rinvgammaOCL(100, shape = sh, rate = rt)
ks_p <- ks.test(ref_sim, ocl_sim)$p.value
message(sprintf("📊 [Test-Profil] rinvgammaOCL KS p-value: %.6f", ks_p))
expect_true(ks_p > 0.01)
