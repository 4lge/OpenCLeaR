source("setup.R", local = TRUE)

if (!isTRUE(getOption("OpenCLeaR.initialized"))) exit_file("no OpenCL device available")

set.seed(42)

# KS-Test validiert die stochastische Simulation des Ziehens ohne Zurücklegen
ks_res <- ks.test(stats::rhyper(100, m = 10, n = 7, k = 8), rhyperOCL(100, m = 10, n = 7, k = 8))

message(sprintf("📊 [Test-Profil] rhyperOCL KS test p-value: %.6f", ks_res$p.value))
expect_true(ks_res$p.value > 0.01)
