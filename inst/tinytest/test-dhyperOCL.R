source("setup.R", local = TRUE)

if (!isTRUE(getOption("OpenCLeaR.initialized"))) exit_file("no OpenCL device available")

# 📊 TEST D-FUNKTION (PMF-Abgleich Hypergeometrisch)
# m = 10 weiße Kugeln, n = 7 schwarze Kugeln, k = 8 Züge
x_test <- 0:8
d_r    <- stats::dhyper(x_test, m = 10, n = 7, k = 8)
d_ocl  <- dhyperOCL(x_test, m = 10, n = 7, k = 8)

max_diff_d <- max(abs(d_r - d_ocl), na.rm = TRUE)

message(sprintf("📊 [Test-Profil] dhyperOCL max diff: %.8f", max_diff_d))
expect_true(max_diff_d < 1e-5)
