source("setup.R", local = TRUE)

if (!isTRUE(getOption("OpenCLeaR.initialized"))) exit_file("no OpenCL device available")

# 📊 TEST D-FUNKTION (PMF-Abgleich Geometrisch)
x_test <- 0:15
d_r    <- stats::dgeom(x_test, prob = 0.25)
d_ocl  <- dgeomOCL(x_test, prob = 0.25)

max_diff_d <- max(abs(d_r - d_ocl), na.rm = TRUE)

message(sprintf("📊 [Test-Profil] dgeomOCL max diff: %.8f", max_diff_d))
expect_true(max_diff_d < 1e-5)
