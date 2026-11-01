source("setup.R", local = TRUE)
if (!isTRUE(getOption("OpenCLeaR.initialized"))) exit_file("no OpenCL device available")

set.seed(1234)
x_vals =  seq(0.1,10,by=0.01)
sh <- 3.5
rt <- 2.1

# Referenz-Funktionen über R-Base Gamma Verknüpfungen
R_dinvgamma <- function(x, shape, rate) { exp(shape*log(rate) - lgamma(shape) - (shape+1)*log(x) - (rate/x)) }

# Tests für d/p/q
ocl_d <- dinvgammaOCL(x_vals, sh, rt); ref_d <- R_dinvgamma(x_vals, sh, rt)
expect_equal(ocl_d, ref_d, tolerance = 1e-4)
max_diff_d <- max(abs(ocl_d - ref_d), na.rm = TRUE)
message(sprintf("📊 [Test-Profil] dinvgammaOCL max abs diff: %.6e", max_diff_d))
