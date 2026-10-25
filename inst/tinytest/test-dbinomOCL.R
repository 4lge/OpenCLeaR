source("setup.R", local = TRUE)

if (!isTRUE(getOption("OpenCLeaR.initialized"))) exit_file("no OpenCL device available")

# 📊 TEST D-FUNKTION (PMF-Abgleich Binomial)
x_test <- 0:20
d_r    <- stats::dbinom(x_test, size = 20, prob = 0.3)
d_ocl  <- dbinomOCL(x_test, size = 20, prob = 0.3)

max_diff_d <- max(abs(d_r - d_ocl), na.rm = TRUE)

message(sprintf("📊 [Test-Profil] dbinomOCL max diff: %.8f", max_diff_d))
expect_true(max_diff_d < 1e-5)
