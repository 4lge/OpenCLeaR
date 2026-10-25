source("setup.R", local = TRUE)

if (!isTRUE(getOption("OpenCLeaR.initialized"))) exit_file("no OpenCL device available")

# 📊 TEST Q-FUNKTION (Quantils-Abgleich Negative Binomial)
p_test <- seq(0.01, 0.99, length.out = 50)
q_r    <- stats::qnbinom(p_test, size = 5, prob = 0.4)
q_ocl  <- qnbinomOCL(p_test, size = 5, prob = 0.4)

max_diff_q <- max(abs(q_r - q_ocl), na.rm = TRUE)

message(sprintf("📊 [Test-Profil] qnbinomOCL max diff: %.8f", max_diff_q))
expect_true(max_diff_q == 0) # Diskrete Ergebnisse müssen absolut übereinstimmen
