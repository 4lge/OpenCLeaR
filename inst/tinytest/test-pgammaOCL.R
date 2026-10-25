source("setup.R", local = TRUE)

if (!isTRUE(getOption("OpenCLeaR.initialized"))) exit_file("no OpenCL device available")

# 📊 TEST P-FUNKTION (CDF-Abgleich Gamma)
q_test <- seq(0.1, 10, length.out = 100)
p_r    <- stats::pgamma(q_test, shape = 2, rate = 0.5)
p_ocl  <- pgammaOCL(q_test, shape = 2, rate = 0.5)

max_diff_p <- max(abs(p_r - p_ocl), na.rm = TRUE)

message(sprintf("📊 [Test-Profil] pgammaOCL max diff: %.8f", max_diff_p))
expect_true(max_diff_p < 1e-5)
