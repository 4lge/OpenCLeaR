source("setup.R", local = TRUE)

if (!isTRUE(getOption("OpenCLeaR.initialized"))) exit_file("no OpenCL device available")

set.seed(42)

p_val=NULL
ks_res <- ks.test(rt(100,1),rtOCL(100,1))
expect_true(ks_res$p.value > 0.01)
p_val = c(p_val, ks_res$p.value)
ks_res <- ks.test(rt(100,10),rtOCL(100,10))
expect_true(ks_res$p.value > 0.01)
p_val = c(p_val, ks_res$p.value)
ks_res <- ks.test(rt(100,42),rtOCL(100,42))
expect_true(ks_res$p.value > 0.01)
p_val = c(p_val, ks_res$p.value)

message(sprintf("📊 [Test-Profil] rtOCL KS test p-values: %.6f, %.6f, %.6f ", p_val[1], p_val[2],p_val[3]))
