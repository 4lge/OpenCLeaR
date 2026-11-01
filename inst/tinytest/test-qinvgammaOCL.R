source("setup.R", local = TRUE)
if (!isTRUE(getOption("OpenCLeaR.initialized"))) exit_file("no OpenCL device available")

set.seed(1234)
p_vals <- seq(0.01, 0.99, length.out = 50)
sh <- 3.5
rt <- 2.1

# Referenz-Funktionen über R-Base Gamma Verknüpfungen
R_qinvgamma <- function(p, shape, rate) { 1.0 / stats::qgamma(1.0 - p, shape = shape, rate = rate) }

ocl_q <- qinvgammaOCL(p_vals, sh, rt); ref_q <- R_qinvgamma(p_vals, sh, rt)
expect_equal(ocl_q, ref_q, tolerance = 1e-4)
max_diff_q <- max(abs(ocl_q - ref_q), na.rm = TRUE)
message(sprintf("📊 [Test-Profil] qinvgammaOCL max abs diff: %.6e", max_diff_q))
