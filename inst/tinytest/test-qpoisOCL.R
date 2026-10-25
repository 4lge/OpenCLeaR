source("setup.R", local = TRUE)

if (!isTRUE(getOption("OpenCLeaR.initialized"))) exit_file("no OpenCL device available")

# 📊 TEST Q-FUNKTION (Quantils-Abgleich Poisson)
p_test <- seq(0.01, 0.99, length.out = 50)
q_r    <- stats::qpois(p_test, lambda = 4)
q_ocl  <- qpoisOCL(p_test, lambda = 4)

max_diff_q <- max(abs(q_r - q_ocl), na.rm = TRUE)

message(sprintf("📊 [Test-Profil] qpoisOCL max diff: %.8f", max_diff_q))
expect_true(max_diff_q == 0) # Diskrete Ergebnisse müssen absolut identisch sein
