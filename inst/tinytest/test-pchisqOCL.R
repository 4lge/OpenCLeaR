source("setup.R", local = TRUE)

if (!isTRUE(getOption("OpenCLeaR.initialized"))) exit_file("no OpenCL device available")

# 📊 TEST P-FUNKTION (CDF-Abgleich Chi-Quadrat)
q_test <- seq(0.1, 20, length.out = 100)
p_r    <- stats::pchisq(q_test, df = 5)
p_ocl  <- pchisqOCL(q_test, df = 5)

max_diff_p <- max(abs(p_r - p_ocl), na.rm = TRUE)

message(sprintf("📊 [Test-Profil] pchisqOCL max diff: %.8f", max_diff_p))
expect_true(max_diff_p < 1e-5)
