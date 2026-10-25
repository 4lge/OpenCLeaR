source("setup.R", local = TRUE)

if (!isTRUE(getOption("OpenCLeaR.initialized"))) exit_file("no OpenCL device available")

# 📊 TEST D-FUNKTION (Dichte-Abgleich Weibull)
x_test <- seq(0.1, 5, length.out = 100)
d_r    <- stats::dweibull(x_test, shape = 1.5, scale = 2.0)
d_ocl  <- dweibullOCL(x_test, shape = 1.5, scale = 2.0)

max_diff_d <- max(abs(d_r - d_ocl), na.rm = TRUE)

message(sprintf("📊 [Test-Profil] dweibullOCL max diff: %.8f", max_diff_d))
expect_true(max_diff_d < 1e-5)
