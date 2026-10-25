source("setup.R", local = TRUE)

if (!isTRUE(getOption("OpenCLeaR.initialized"))) exit_file("no OpenCL device available")

# 📊 TEST D-FUNKTION (Dichte-Abgleich Gamma)
x_test <- seq(0.1, 10, length.out = 100)
d_r    <- stats::dgamma(x_test, shape = 2, rate = 0.5)
d_ocl  <- dgammaOCL(x_test, shape = 2, rate = 0.5)

max_diff_d <- max(abs(d_r - d_ocl), na.rm = TRUE)

message(sprintf("📊 [Test-Profil] dgammaOCL max diff: %.8f", max_diff_d))
expect_true(max_diff_d < 1e-5)
