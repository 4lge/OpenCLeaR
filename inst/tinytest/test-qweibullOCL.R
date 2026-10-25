source("setup.R", local = TRUE)

if (!isTRUE(getOption("OpenCLeaR.initialized"))) exit_file("no OpenCL device available")

# 📊 TEST Q-FUNKTION (Quantils-Abgleich Weibull)
p_test <- seq(0.01, 0.99, length.out = 100)
q_r    <- stats::qweibull(p_test, shape = 1.5, scale = 2.0)
q_ocl  <- qweibullOCL(p_test, shape = 1.5, scale = 2.0)

max_diff_q <- max(abs(q_r - q_ocl), na.rm = TRUE)

message(sprintf("📊 [Test-Profil] qweibullOCL max diff: %.8f", max_diff_q))
expect_true(max_diff_q < 1e-5) # Da geschlossen analytisch lösbar, sehr scharfe Toleranz
