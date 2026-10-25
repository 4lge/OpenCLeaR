source("setup.R", local = TRUE)

if (!isTRUE(getOption("OpenCLeaR.initialized"))) exit_file("no OpenCL device available")

# 📊 TEST P-FUNKTION (CDF-Abgleich Beta)
q_test <- seq(0.01, 0.99, length.out = 100)
p_r    <- stats::pbeta(q_test, shape1 = 2, shape2 = 5)
p_ocl  <- pbetaOCL(q_test, shape1 = 2, shape2 = 5)

max_diff_p <- max(abs(p_r - p_ocl), na.rm = TRUE)

message(sprintf("📊 [Test-Profil] pbetaOCL max diff: %.8f", max_diff_p))
expect_true(max_diff_p < 1e-5)
