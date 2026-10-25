source("setup.R", local = TRUE)

if (!isTRUE(getOption("OpenCLeaR.initialized"))) exit_file("no OpenCL device available")

# 📊 TEST D-FUNKTION (Dichte-Abgleich Cauchy)
x_test <- seq(-5, 5, length.out = 100)
d_r    <- stats::dcauchy(x_test, location = 0, scale = 1)
d_ocl  <- dcauchyOCL(x_test, location = 0, scale = 1)

max_diff_d <- max(abs(d_r - d_ocl), na.rm = TRUE)

message(sprintf("📊 [Test-Profil] dcauchyOCL max diff: %.8f", max_diff_d))
expect_true(max_diff_d < 1e-5)
