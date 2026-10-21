source("setup.R", local = TRUE)

if (!isTRUE(getOption("OpenCLeaR.initialized"))) exit_file("no OpenCL device available")

# 📊 TEST D-FUNKTION (Dichte-Abgleich)
x_test <- seq(-4, 4, length.out = 100)
d_r    <- stats::dnorm(x_test, mean = 0, sd = 1)
d_ocl  <- dnormOCL(x_test, mean = 0, sd = 1)

max_diff_d <- max(abs(d_r - d_ocl))

message(sprintf("📊 [Test-Profil] dnormOCL max diff: %.8f", max_diff_d))
expect_true(max_diff_d < 1e-5)
