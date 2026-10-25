source("setup.R", local = TRUE)

if (!isTRUE(getOption("OpenCLeaR.initialized"))) exit_file("no OpenCL device available")

set.seed(42)

# KS-Test vergleicht nativen R-Generator mit OpenCL (Stochastischer Quotient aus zwei Chi-Quadrat-Variablen)
ks_res <- ks.test(stats::rf(100, df1 = 5, df2 = 10), rfOCL(100, df1 = 5, df2 = 10))

message(sprintf("📊 [Test-Profil] rfOCL KS test p-value: %.6f", ks_res$p.value))
expect_true(ks_res$p.value > 0.01)
