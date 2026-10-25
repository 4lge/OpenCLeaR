source("setup.R", local = TRUE)

if (!isTRUE(getOption("OpenCLeaR.initialized"))) exit_file("no OpenCL device available")

# 📊 TEST P-FUNKTION (CDF-Abgleich Negative Binomial)
q_test <- 0:30
p_r    <- stats::pnbinom(q_test, size = 5, prob = 0.4)
p_ocl  <- pnbinomOCL(q_test, size = 5, prob = 0.4)

max_diff_p <- max(abs(p_r - p_ocl), na.rm = TRUE)

message(sprintf("📊 [Test-Profil] pnbinomOCL max diff: %.8f", max_diff_p))
expect_true(max_diff_p < 1e-5)
