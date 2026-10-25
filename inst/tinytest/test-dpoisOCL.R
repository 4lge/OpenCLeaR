source("setup.R", local = TRUE)

if (!isTRUE(getOption("OpenCLeaR.initialized"))) exit_file("no OpenCL device available")

# 📊 TEST D-FUNKTION (PMF-Abgleich Poisson)
x_test <- 0:25
d_r    <- stats::dpois(x_test, lambda = 4)
d_ocl  <- dpoisOCL(x_test, lambda = 4)

max_diff_d <- max(abs(d_r - d_ocl), na.rm = TRUE)

message(sprintf("📊 [Test-Profil] dpoisOCL max diff: %.8f", max_diff_d))
expect_true(max_diff_d < 1e-5)
