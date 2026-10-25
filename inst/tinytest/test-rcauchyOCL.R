source("setup.R", local = TRUE)

if (!isTRUE(getOption("OpenCLeaR.initialized"))) exit_file("no OpenCL device available")

set.seed(42)

# KS-Test vergleicht nativen R-Generator mit OpenCL (Inversionsmethode via tan)
ks_res <- ks.test(stats::rcauchy(100, location = 0, scale = 1), rcauchyOCL(100, location = 0, scale = 1))

message(sprintf("📊 [Test-Profil] rcauchyOCL KS test p-value: %.6f", ks_res$p.value))
expect_true(ks_res$p.value > 0.01)
