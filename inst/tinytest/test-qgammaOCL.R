source("setup.R", local = TRUE)

if (!isTRUE(getOption("OpenCLeaR.initialized"))) exit_file("no OpenCL device available")

# 📊 TEST Q-FUNKTION (Quantils-Abgleich Gamma)
p_test <- seq(0.01, 0.99, length.out = 100)
q_r    <- stats::qgamma(p_test, shape = 2, rate = 0.5)
q_ocl  <- qgammaOCL(p_test, shape = 2, rate = 0.5)

max_diff_q <- max(abs(q_r - q_ocl), na.rm = TRUE)

message(sprintf("📊 [Test-Profil] qgammaOCL max diff: %.8f", max_diff_q))
expect_true(max_diff_q < 1e-3) # Etwas weichere Toleranz wegen JIT Newton-Schleife
