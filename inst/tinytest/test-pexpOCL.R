source("setup.R", local = TRUE)

if (!isTRUE(getOption("OpenCLeaR.initialized"))) exit_file("no OpenCL device available")

# 📊 TEST P-FUNKTION (CDF-Abgleich Exponential)
q_test <- seq(0, 5, length.out = 100)
p_r    <- stats::pexp(q_test, rate = 1.5)
p_ocl  <- pexpOCL(q_test, rate = 1.5)

max_diff_p <- max(abs(p_r - p_ocl), na.rm = TRUE)

message(sprintf("📊 [Test-Profil] pexpOCL max diff: %.8f", max_diff_p))
expect_true(max_diff_p < 1e-5)
