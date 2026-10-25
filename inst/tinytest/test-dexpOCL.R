source("setup.R", local = TRUE)

if (!isTRUE(getOption("OpenCLeaR.initialized"))) exit_file("no OpenCL device available")

# 📊 TEST D-FUNKTION (Dichte-Abgleich Exponential)
x_test <- seq(0, 5, length.out = 100)
d_r    <- stats::dexp(x_test, rate = 1.5)
d_ocl  <- dexpOCL(x_test, rate = 1.5)

max_diff_d <- max(abs(d_r - d_ocl), na.rm = TRUE)

message(sprintf("📊 [Test-Profil] dexpOCL max diff: %.8f", max_diff_d))
expect_true(max_diff_d < 1e-5)
