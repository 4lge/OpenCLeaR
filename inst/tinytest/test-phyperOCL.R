source("setup.R", local = TRUE)

if (!isTRUE(getOption("OpenCLeaR.initialized"))) exit_file("no OpenCL device available")

# 📊 TEST P-FUNKTION (CDF-Abgleich Hypergeometrisch)
q_test <- 0:8
p_r    <- stats::phyper(q_test, m = 10, n = 7, k = 8)
p_ocl  <- phyperOCL(q_test, m = 10, n = 7, k = 8)

max_diff_p <- max(abs(p_r - p_ocl), na.rm = TRUE)

message(sprintf("📊 [Test-Profil] phyperOCL max diff: %.8f", max_diff_p))
expect_true(max_diff_p < 1e-5)
