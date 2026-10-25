source("setup.R", local = TRUE)

if (!isTRUE(getOption("OpenCLeaR.initialized"))) exit_file("no OpenCL device available")

# 📊 TEST D-FUNKTION (Dichte-Abgleich Chi-Quadrat)
x_test <- seq(0.1, 20, length.out = 100)
d_r    <- stats::dchisq(x_test, df = 5)
d_ocl  <- dchisqOCL(x_test, df = 5)

max_diff_d <- max(abs(d_r - d_ocl), na.rm = TRUE)

message(sprintf("📊 [Test-Profil] dchisqOCL max diff: %.8f", max_diff_d))
expect_true(max_diff_d < 1e-5)
