source("setup.R", local = TRUE)

if (!isTRUE(getOption("OpenCLeaR.initialized"))) exit_file("no OpenCL device available")

# 📊 TEST Q-FUNKTION (Quantils-Abgleich Gleichverteilung)
p_test <- seq(0.01, 0.99, length.out = 100)
q_r    <- stats::qunif(p_test, min = 0, max = 5)
q_ocl  <- qunifOCL(p_test, min = 0, max = 5)

max_diff_q <- max(abs(q_r - q_ocl), na.rm = TRUE)

message(sprintf("📊 [Test-Profil] qunifOCL max diff: %.8f", max_diff_q))
expect_true(max_diff_q < 1e-5) # Exakt analytisch lösbar, daher scharfe Toleranz
