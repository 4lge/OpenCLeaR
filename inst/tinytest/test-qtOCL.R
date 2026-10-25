source("setup.R", local = TRUE)

if (!isTRUE(getOption("OpenCLeaR.initialized"))) exit_file("no OpenCL device available")

# 📊 TEST Q-FUNKTION (Quantils-Abgleich Student-t)
p_test <- seq(0.02, 0.98, length.out = 100)
q_r    <- stats::qt(p_test, df = 5)
q_ocl  <- qtOCL(p_test, df = 5)

max_diff_q <- max(abs(q_r - q_ocl), na.rm = TRUE)

message(sprintf("📊 [Test-Profil] qtOCL max diff: %.8f", max_diff_q))
expect_true(max_diff_q < 1e-3) # Numerische Inversions-Toleranz
