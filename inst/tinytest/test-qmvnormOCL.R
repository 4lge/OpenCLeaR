source("setup.R", local = TRUE)

if (!isTRUE(getOption("OpenCLeaR.initialized"))) exit_file("no OpenCL device available")

mu3 <- c(1, 2, 3)
Sigma3 <- matrix(c(1,    0.5,  0.25,
                   0.5,  1,    0.5,
                   0.25, 0.5,  1), nrow = 3, ncol = 3)

# =========================================================================
# TEST QMVNORM (All 3 tail modes + boundary values ​​p=0, p=1 + dim=1)
# =========================================================================
for (t_mode in c("lower.tail", "upper.tail", "both.tails")) {
    probs <- if (t_mode == "both.tails") c(0.50, 0.90, 0.95) else c(0.25, 0.90, 0.95)
    for (prob in probs) {
        q_r   <- mvtnorm::qmvnorm(prob, tail = t_mode, mean = mu3, sigma = Sigma3)$quantile
        q_ocl <- as.numeric(qmvnormOCL(prob, tail = t_mode, mean = mu3, sigma = Sigma3, n = 2e6L))
        diff_q <- abs(q_r - q_ocl)
        message(sprintf("📊 [qmvnormOCL | %-10s | p=%.2f] diff: %.6f", t_mode, prob, diff_q))
        expect_true(diff_q < 0.015)
    }
}

# Marginal values ​​p = 0 and p = 1
expect_equal(as.numeric(qmvnormOCL(0, tail = "both.tails", mean = mu3, sigma = Sigma3)), 0)
expect_equal(as.numeric(qmvnormOCL(0, tail = "lower.tail", mean = mu3, sigma = Sigma3)), -Inf)
expect_equal(as.numeric(qmvnormOCL(1, tail = "lower.tail", mean = mu3, sigma = Sigma3)), Inf)

# =========================================================================
# ERROR HANDLING (Non-positive definite matrix & dimensional errors)
# =========================================================================
Sigma_bad <- matrix(c(1, 2, 2, 1), 2, 2) # Eigenwerte: 3 und -1 -> nicht positiv definit!
expect_true(is.nan(as.numeric(qmvnormOCL(0.95, mean = c(0, 0), sigma = Sigma_bad))))
