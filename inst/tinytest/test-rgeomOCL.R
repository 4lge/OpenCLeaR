source("setup.R", local = TRUE)

if (!isTRUE(getOption("OpenCLeaR.initialized"))) exit_file("no OpenCL device available")

set.seed(42)

# KS-Test vergleicht nativen R-Generator mit OpenCL (Inversion via kontinuierliche Exponentialtransformation)
ks_res <- ks.test(stats::rgeom(100, prob = 0.25), rgeomOCL(100, prob = 0.25))

message(sprintf("📊 [Test-Profil] rgeomOCL KS test p-value: %.6f", ks_res$p.value))
expect_true(ks_res$p.value > 0.01)
