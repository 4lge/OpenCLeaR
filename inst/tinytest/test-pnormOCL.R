source("setup.R", local = TRUE)

if (!isTRUE(getOption("OpenCLeaR.initialized"))) exit_file("no OpenCL device available")

# 📊 TEST P-FUNKTION (CDF-Abgleich)
q_test <- seq(-4, 4, length.out = 100)
p_r    <- stats::pnorm(q_test, mean = 0, sd = 1)
p_ocl  <- pnormOCL(q_test, mean = 0, sd = 1)

max_diff_p <- max(abs(p_r - p_ocl))

message(sprintf("📊 [Test-Profil] pnormOCL max diff: %.8f", max_diff_p))
expect_true(max_diff_p < 1e-5)
