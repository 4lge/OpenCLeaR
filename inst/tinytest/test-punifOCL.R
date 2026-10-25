source("setup.R", local = TRUE)

if (!isTRUE(getOption("OpenCLeaR.initialized"))) exit_file("no OpenCL device available")

# 📊 TEST P-FUNKTION (CDF-Abgleich Gleichverteilung)
q_test <- seq(-1, 6, length.out = 100)
p_r    <- stats::punif(q_test, min = 0, max = 5)
p_ocl  <- punifOCL(q_test, min = 0, max = 5)

max_diff_p <- max(abs(p_r - p_ocl), na.rm = TRUE)

message(sprintf("📊 [Test-Profil] punifOCL max diff: %.8f", max_diff_p))
expect_true(max_diff_p < 1e-5)
