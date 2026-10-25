source("setup.R", local = TRUE)

if (!isTRUE(getOption("OpenCLeaR.initialized"))) exit_file("no OpenCL device available")

# 📊 TEST Q-FUNKTION (Quantils-Abgleich Log-Normal)
p_test <- seq(0.01, 0.99, length.out = 100)
q_r    <- stats::qlnorm(p_test, meanlog = 0, sdlog = 1)
q_ocl  <- qlnormOCL(p_test, meanlog = 0, sdlog = 1)

max_diff_q <- max(abs(q_r - q_ocl), na.rm = TRUE)

message(sprintf("📊 [Test-Profil] qlnormOCL max diff: %.8f", max_diff_q))
expect_true(max_diff_q < 1e-4) # Durch Verknüpfung mit qnorm scharf tolerierbar
