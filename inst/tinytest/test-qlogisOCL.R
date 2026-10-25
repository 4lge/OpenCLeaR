source("setup.R", local = TRUE)

if (!isTRUE(getOption("OpenCLeaR.initialized"))) exit_file("no OpenCL device available")

# 📊 TEST Q-FUNKTION (Quantils-Abgleich Logistisch)
p_test <- seq(0.01, 0.99, length.out = 100)
q_r    <- stats::qlogis(p_test, location = 0, scale = 1)
q_ocl  <- qlogisOCL(p_test, location = 0, scale = 1)

max_diff_q <- max(abs(q_r - q_ocl), na.rm = TRUE)

message(sprintf("📊 [Test-Profil] qlogisOCL max diff: %.8f", max_diff_q))
expect_true(max_diff_q < 1e-5) # Da geschlossen analytisch, sehr scharfe Toleranz
