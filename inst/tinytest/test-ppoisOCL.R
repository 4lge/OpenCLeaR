source("setup.R", local = TRUE)

if (!isTRUE(getOption("OpenCLeaR.initialized"))) exit_file("no OpenCL device available")

# 📊 TEST P-FUNKTION (CDF-Abgleich Poisson)
q_test <- 0:25
p_r    <- stats::ppois(q_test, lambda = 4)
p_ocl  <- ppoisOCL(q_test, lambda = 4)

max_diff_p <- max(abs(p_r - p_ocl), na.rm = TRUE)

message(sprintf("📊 [Test-Profil] ppoisOCL max diff: %.8f", max_diff_p))
expect_true(max_diff_p < 1e-5)
