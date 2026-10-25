source("setup.R", local = TRUE)

if (!isTRUE(getOption("OpenCLeaR.initialized"))) exit_file("no OpenCL device available")

set.seed(42)

# KS-Test validiert die diskrete Inversions-Treppensuche auf dem OpenCL-Kern
ks_res <- ks.test(stats::rnbinom(100, size = 5, prob = 0.4), rnbinomOCL(100, size = 5, prob = 0.4))

message(sprintf("📊 [Test-Profil] rnbinomOCL KS test p-value: %.6f", ks_res$p.value))
expect_true(ks_res$p.value > 0.01)
