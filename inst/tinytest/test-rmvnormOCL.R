source("setup.R", local = TRUE)

if (!isTRUE(getOption("OpenCLeaR.initialized"))) exit_file("no OpenCL device available")

# 📊 TEST RNG
mu3 <- c(1, 2, 3)
Sigma3 <- matrix(c(1.0,  0.5,  0.25,
                   0.5,  1.0,  0.5,
                   0.25, 0.5,  1.0), nrow = 3, ncol = 3)

pts <- rmvnormOCL(1000L, mean = mu3, sigma = Sigma3)
samples <- rmvnormOCL(200000L, mean = mu3, sigma = Sigma3)

expect_equal(dim(samples), c(200000L, 3L))
max_diff_mu  <- max(abs(colMeans(samples) - mu3))
max_diff_cov <- max(abs(cov(samples) - Sigma3))

## test only mean and cov for now.

message(sprintf("📊 [rmvnormOCL] max diff mean: %.6f | cov: %.6f", max_diff_mu, max_diff_cov))
expect_true(max_diff_mu  < 0.01)
expect_true(max_diff_cov < 0.015)

# ERROR HANDLING (Non-positive definite matrix & dimensional errors)
Sigma_bad <- matrix(c(1, 2, 2, 1), 2, 2) # eigenvalues: 3 and -1 -> not positive definite!
expect_true(all(is.nan(rmvnormOCL(10L, mean = c(0, 0), sigma = Sigma_bad))))

# Dimensional mismatch
expect_error(rmvnormOCL(10L, mean = c(0, 0, 0), sigma = diag(2)))
