source("setup.R", local = TRUE)

if (!isTRUE(getOption("OpenCLeaR.initialized"))) exit_file("no OpenCL device available")

# 📊 TEST Q-FUNKTION (Quantils-Abgleich Geometrisch)
p_test <- seq(0.01, 0.99, length.out = 50)
q_r    <- stats::qgeom(p_test, prob = 0.25)
q_ocl  <- qgeomOCL(p_test, prob = 0.25)

max_diff_q <- max(abs(q_r - q_ocl), na.rm = TRUE)

message(sprintf("📊 [Test-Profil] qgeomOCL max diff: %.8f", max_diff_q))
expect_true(max_diff_q == 0) # Diskrete Quantile müssen exakt matchen
