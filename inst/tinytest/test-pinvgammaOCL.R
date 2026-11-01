source("setup.R", local = TRUE)
if (!isTRUE(getOption("OpenCLeaR.initialized"))) exit_file("no OpenCL device available")

set.seed(1234)
x_vals =  seq(0.1,10,by=0.01)
p_vals <- seq(0.01, 0.99, length.out = 50)
sh <- 3.5
rt <- 2.1

# Referenz-Funktionen über R-Base Gamma Verknüpfungen
R_pinvgamma <- function(q, shape, rate) { 1.0 - stats::pgamma(1.0/q, shape = shape, rate = rate) }

ocl_p <- pinvgammaOCL(x_vals, sh, rt); ref_p <- R_pinvgamma(x_vals, sh, rt)
expect_equal(ocl_p, ref_p, tolerance = 1e-4)
max_diff_p <- max(abs(ocl_p - ref_p), na.rm = TRUE)
message(sprintf("📊 [Test-Profil] pinvgammaOCL max abs diff: %.6e", max_diff_p))

