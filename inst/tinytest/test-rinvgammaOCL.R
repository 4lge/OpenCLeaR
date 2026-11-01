source("setup.R", local = TRUE)
if (!isTRUE(getOption("OpenCLeaR.initialized"))) exit_file("no OpenCL device available")

set.seed(1234)
sh <- 3.5
rt <- 2.1


# RNG KS-Test
ref_sim <- 1.0 / stats::rgamma(100, shape = sh, rate = rt)
ocl_sim <- rinvgammaOCL(100, shape = sh, rate = rt)
ks_p <- ks.test(ref_sim, ocl_sim)$p.value
message(sprintf("📊 [Test-Profil] rinvgammaOCL KS p-value: %.6f", ks_p))
expect_true(ks_p > 0.01)
