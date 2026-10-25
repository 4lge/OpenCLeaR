source("setup.R", local = TRUE)

if (!isTRUE(getOption("OpenCLeaR.initialized"))) exit_file("no OpenCL device available")

set.seed(42)

# KS-Test validiert den Knuth-Simulationspfad auf der GPU
ks_res <- ks.test(stats::rpois(100, lambda = 4), rpoisOCL(100, lambda = 4))

message(sprintf("📊 [Test-Profil] rpoisOCL KS test p-value: %.6f", ks_res$p.value))
expect_true(ks_res$p.value > 0.01)
