source("setup.R", local = TRUE)

if (!isTRUE(getOption("OpenCLeaR.initialized"))) exit_file("no OpenCL device available")

set.seed(42)

# KS-Test vergleicht nativen R-Generator mit OpenCL (Inversionsmethode via pow/log)
ks_res <- ks.test(stats::rweibull(100, shape = 1.5, scale = 2.0), rweibullOCL(100, shape = 1.5, scale = 2.0))

message(sprintf("📊 [Test-Profil] rweibullOCL KS test p-value: %.6f", ks_res$p.value))
expect_true(ks_res$p.value > 0.01)
