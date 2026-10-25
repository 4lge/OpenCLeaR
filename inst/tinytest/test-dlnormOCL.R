source("setup.R", local = TRUE)

if (!isTRUE(getOption("OpenCLeaR.initialized"))) exit_file("no OpenCL device available")

# 📊 TEST D-FUNKTION (Dichte-Abgleich Log-Normal)
x_test <- seq(0.1, 10, length.out = 100)
d_r    <- stats::dlnorm(x_test, meanlog = 0, sdlog = 1)
d_ocl  <- dlnormOCL(x_test, meanlog = 0, sdlog = 1)

max_diff_d <- max(abs(d_r - d_ocl), na.rm = TRUE)

message(sprintf("📊 [Test-Profil] dlnormOCL max diff: %.8f", max_diff_d))
expect_true(max_diff_d < 1e-5)
