source("setup.R", local = TRUE)

if (!isTRUE(getOption("OpenCLeaR.initialized"))) exit_file("no OpenCL device available")

# 📊 TEST P-FUNKTION (CDF-Abgleich F-Verteilung)
q_test <- seq(0.1, 10, length.out = 100)
p_r    <- stats::pf(q_test, df1 = 5, df2 = 10)
p_ocl  <- pfOCL(q_test, df1 = 5, df2 = 10)

max_diff_p <- max(abs(p_r - p_ocl), na.rm = TRUE)

message(sprintf("📊 [Test-Profil] pfOCL max diff: %.8f", max_diff_p))
expect_true(max_diff_p < 1e-5)
