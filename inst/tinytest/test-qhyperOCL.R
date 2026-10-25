source("setup.R", local = TRUE)

if (!isTRUE(getOption("OpenCLeaR.initialized"))) exit_file("no OpenCL device available")

# 📊 TEST Q-FUNKTION (Quantils-Abgleich Hypergeometrisch)
p_test <- seq(0.01, 0.99, length.out = 50)
q_r    <- stats::qhyper(p_test, m = 10, n = 7, k = 8)
q_ocl  <- qhyperOCL(p_test, m = 10, n = 7, k = 8)

max_diff_q <- max(abs(q_r - q_ocl), na.rm = TRUE)

message(sprintf("📊 [Test-Profil] qhyperOCL max diff: %.8f", max_diff_q))
expect_true(max_diff_q == 0) # Diskrete Ergebnisse müssen absolut identisch sein
