source("setup.R", local = TRUE)

if (!isTRUE(getOption("OpenCLeaR.initialized"))) exit_file("no OpenCL device available")

# 📊 TEST Q-FUNKTION (Quantils-Abgleich Beta via Newton-Raphson)
p_test <- seq(0.05, 0.95, length.out = 100)
q_r    <- stats::qbeta(p_test, shape1 = 2, shape2 = 5)
q_ocl  <- qbetaOCL(p_test, shape1 = 2, shape2 = 5)

max_diff_q <- max(abs(q_r - q_ocl), na.rm = TRUE)

message(sprintf("📊 [Test-Profil] qbetaOCL max diff: %.8f", max_diff_q))
expect_true(max_diff_q < 1e-3) # Newton-Raphson Toleranz
