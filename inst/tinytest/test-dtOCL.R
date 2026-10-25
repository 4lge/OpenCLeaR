source("setup.R", local = TRUE)

if (!isTRUE(getOption("OpenCLeaR.initialized"))) exit_file("no OpenCL device available")

# 📊 TEST D-FUNKTION (Dichte-Abgleich Student-t)
x_test <- seq(-4, 4, length.out = 100)
d_r    <- stats::dt(x_test, df = 5)
d_ocl  <- dtOCL(x_test, df = 5)

max_diff_d <- max(abs(d_r - d_ocl), na.rm = TRUE)

message(sprintf("📊 [Test-Profil] dtOCL max diff: %.8f", max_diff_d))
expect_true(max_diff_d < 1e-5)
