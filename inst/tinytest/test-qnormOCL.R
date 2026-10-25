source("setup.R", local = TRUE)

if (!isTRUE(getOption("OpenCLeaR.initialized"))) exit_file("no OpenCL device available")

# 📊 TEST Q-FUNKTION (Quantils-Abgleich via Newton-Raphson)
p_test <- seq(0.001, 0.999, length.out = 100)
q_r    <- stats::qnorm(p_test, mean = 0, sd = 1)
q_ocl  <- qnormOCL(p_test, mean = 0, sd = 1)

max_diff_q <- max(abs(q_r - q_ocl))

message(sprintf("📊 [Test-Profil] qnormOCL max diff: %.8f", max_diff_q))
expect_true(max_diff_q < 1e-4) # Etwas weichere Toleranz fuer numerische Invertierung
