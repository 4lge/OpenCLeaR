source("setup.R", local = TRUE)

if (!isTRUE(getOption("OpenCLeaR.initialized"))) exit_file("no OpenCL device available")

# 📊 TEST P-FUNKTION (CDF-Abgleich Cauchy)
q_test <- seq(-5, 5, length.out = 100)
p_r    <- stats::pcauchy(q_test, location = 0, scale = 1)
p_ocl  <- pcauchyOCL(q_test, location = 0, scale = 1)

max_diff_p <- max(abs(p_r - p_ocl), na.rm = TRUE)

message(sprintf("📊 [Test-Profil] pcauchyOCL max diff: %.8f", max_diff_p))
expect_true(max_diff_p < 1e-5)
