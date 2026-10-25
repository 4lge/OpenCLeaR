source("setup.R", local = TRUE)

if (!isTRUE(getOption("OpenCLeaR.initialized"))) exit_file("no OpenCL device available")

set.seed(42)

# KS-Test vergleicht nativen R-Generator mit OpenCL Marsaglia-Tsang Implementierung
ks_res <- ks.test(stats::rgamma(100, shape = 2, rate = 0.5), rgammaOCL(100, shape = 2, rate = 0.5))

message(sprintf("📊 [Test-Profil] rgammaOCL KS test p-value: %.6f", ks_res$p.value))
expect_true(ks_res$p.value > 0.01)
