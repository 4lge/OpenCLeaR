source("setup.R", local = TRUE)

if (!isTRUE(getOption("OpenCLeaR.initialized"))) exit_file("no OpenCL device available")

# 📊 TEST D-FUNKTION (Dichte-Abgleich Beta)
x_test <- seq(0.01, 0.99, length.out = 100)
d_r    <- stats::dbeta(x_test, shape1 = 2, shape2 = 5)
d_ocl  <- dbetaOCL(x_test, shape1 = 2, shape2 = 5)

max_diff_d <- max(abs(d_r - d_ocl), na.rm = TRUE)

message(sprintf("📊 [Test-Profil] dbetaOCL max diff: %.8f", max_diff_d))
expect_true(max_diff_d < 1e-5)
