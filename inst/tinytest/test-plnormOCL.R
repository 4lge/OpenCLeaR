source("setup.R", local = TRUE)

if (!isTRUE(getOption("OpenCLeaR.initialized"))) exit_file("no OpenCL device available")

# 📊 TEST P-FUNKTION (CDF-Abgleich Log-Normal)
q_test <- seq(0.1, 10, length.out = 100)
p_r    <- stats::plnorm(q_test, meanlog = 0, sdlog = 1)
p_ocl  <- plnormOCL(q_test, meanlog = 0, sdlog = 1)

max_diff_p <- max(abs(p_r - p_ocl), na.rm = TRUE)

message(sprintf("📊 [Test-Profil] plnormOCL max diff: %.8f", max_diff_p))
expect_true(max_diff_p < 1e-5)
