source("setup.R", local = TRUE)

if (!isTRUE(getOption("OpenCLeaR.initialized"))) exit_file("no OpenCL device available")

# 📊 TEST P-FUNKTION (CDF-Abgleich Binomial)
q_test <- 0:20
p_r    <- stats::pbinom(q_test, size = 20, prob = 0.3)
p_ocl  <- pbinomOCL(q_test, size = 20, prob = 0.3)

max_diff_p <- max(abs(p_r - p_ocl), na.rm = TRUE)

message(sprintf("📊 [Test-Profil] pbinomOCL max diff: %.8f", max_diff_p))
expect_true(max_diff_p < 1e-5)
