source("setup.R", local = TRUE)

if (!isTRUE(getOption("OpenCLeaR.initialized"))) exit_file("no OpenCL device available")

# 📊 TEST D-FUNKTION (Dichte-Abgleich Gleichverteilung)
x_test <- seq(-1, 6, length.out = 100)
d_r    <- stats::dunif(x_test, min = 0, max = 5)
d_ocl  <- dunifOCL(x_test, min = 0, max = 5)

max_diff_d <- max(abs(d_r - d_ocl), na.rm = TRUE)

message(sprintf("📊 [Test-Profil] dunifOCL max diff: %.8f", max_diff_d))
expect_true(max_diff_d < 1e-5)
