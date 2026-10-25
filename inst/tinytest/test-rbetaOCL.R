source("setup.R", local = TRUE)

if (!isTRUE(getOption("OpenCLeaR.initialized"))) exit_file("no OpenCL device available")

set.seed(42)

# KS-Test vergleicht nativen R-Generator mit OpenCL (Zwei-Gamma-Mischung)
ks_res <- ks.test(stats::rbeta(100, shape1 = 2, shape2 = 5), rbetaOCL(100, shape1 = 2, shape2 = 5))

message(sprintf("📊 [Test-Profil] rbetaOCL KS test p-value: %.6f", ks_res$p.value))
expect_true(ks_res$p.value > 0.01)
