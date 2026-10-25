source("setup.R", local = TRUE)

if (!isTRUE(getOption("OpenCLeaR.initialized"))) exit_file("no OpenCL device available")

set.seed(42)

# KS-Test vergleicht nativen R-Generator mit OpenCL (exponentiierte Box-Muller Transformation)
ks_res <- ks.test(stats::rlnorm(100, meanlog = 0, sdlog = 1), rlnormOCL(100, meanlog = 0, sdlog = 1))

message(sprintf("📊 [Test-Profil] rlnormOCL KS test p-value: %.6f", ks_res$p.value))
expect_true(ks_res$p.value > 0.01)
