source("setup.R", local = TRUE)

if (!isTRUE(getOption("OpenCLeaR.initialized"))) exit_file("no OpenCL device available")

# 📊 TEST P-FUNKTION (CDF-Abgleich Weibull)
q_test <- seq(0.1, 5, length.out = 100)
p_r    <- stats::pweibull(q_test, shape = 1.5, scale = 2.0)
p_ocl  <- pweibullOCL(q_test, shape = 1.5, scale = 2.0)

max_diff_p <- max(abs(p_r - p_ocl), na.rm = TRUE)

message(sprintf("📊 [Test-Profil] pweibullOCL max diff: %.8f", max_diff_p))
expect_true(max_diff_p < 1e-5)
