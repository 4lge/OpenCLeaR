source("setup.R", local = TRUE)

if (!isTRUE(getOption("OpenCLeaR.initialized"))) exit_file("no OpenCL device available")

# 📊 TEST D-FUNKTION (PMF-Abgleich Negative Binomial)
x_test <- 0:30
d_r    <- stats::dnbinom(x_test, size = 5, prob = 0.4)
d_ocl  <- dnbinomOCL(x_test, size = 5, prob = 0.4)

max_diff_d <- max(abs(d_r - d_ocl), na.rm = TRUE)

message(sprintf("📊 [Test-Profil] dnbinomOCL max diff: %.8f", max_diff_d))
expect_true(max_diff_d < 1e-5)
