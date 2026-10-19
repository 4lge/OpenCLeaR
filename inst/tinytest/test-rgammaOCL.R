source("setup.R", local = TRUE)

if (!isTRUE(getOption("OpenCLeaR.initialized"))) exit_file("no OpenCL device available")

set.seed(42)

ks_res = ks.test(rgamma(100,1,1),rgammaOCL(100,1,1))

message(sprintf("📊 [Test-Profil] rgammaOCL KS test p-value: %.6f", ks_res$p.value))
expect_true(ks_res$p.value > 0.01)
