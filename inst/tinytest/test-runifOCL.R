source("setup.R", local = TRUE)

if (!isTRUE(getOption("OpenCLeaR.initialized"))) exit_file("no OpenCL device available")

set.seed(42)

# KS-Test vergleicht nativen R-Generator mit OpenCL (Mersenne Twister Skalierung)
ks_res <- ks.test(stats::runif(100, min = 0, max = 5), runifOCL(100, min = 0, max = 5))

message(sprintf("📊 [Test-Profil] runifOCL KS test p-value: %.6f", ks_res$p.value))
expect_true(ks_res$p.value > 0.01)
