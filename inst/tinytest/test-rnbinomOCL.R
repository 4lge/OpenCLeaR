source("setup.R", local = TRUE)

if (!isTRUE(getOption("OpenCLeaR.initialized"))) exit_file("no OpenCL device available")

set.seed(42)

ks_res = ks.test(rnbinom(100,2,0.5),rnbinomOCL(100,2,0.5))

message(sprintf("📊 [Test-Profil] rnbinomOCL KS test p-value: %.6f", ks_res$p.value))
expect_true(ks_res$p.value > 0.01)
