source("setup.R", local = TRUE)

if (!isTRUE(getOption("OpenCLeaR.initialized"))) exit_file("no OpenCL device available")

# 📊 TEST D-FUNKTION (Dichte-Abgleich F-Verteilung)
x_test <- seq(0.1, 10, length.out = 100)
d_r    <- stats::df(x_test, df1 = 5, df2 = 10)
d_ocl  <- dfOCL(x_test, df1 = 5, df2 = 10)

max_diff_d <- max(abs(d_r - d_ocl), na.rm = TRUE)

message(sprintf("📊 [Test-Profil] dfOCL max diff: %.8f", max_diff_d))
expect_true(max_diff_d < 1e-5)
