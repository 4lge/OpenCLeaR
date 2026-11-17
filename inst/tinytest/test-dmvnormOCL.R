source("setup.R", local = TRUE)

if (!isTRUE(getOption("OpenCLeaR.initialized"))) exit_file("no OpenCL device available")

#  TEST D FUNCTION (density adjustment)
mu3 <- c(1, 2, 3)
Sigma3 <- matrix(c(1,    0.5,  0.25,
                   0.5,  1,    0.5,
                   0.25, 0.5,  1), nrow = 3, ncol = 3)

samples <- rmvnormOCL(200000L, mean = mu3, sigma = Sigma3)

expect_equal(dim(samples), c(200000L, 3L))

d_r <- mvtnorm::dmvnorm(samples, mean = mu, sigma = Sigma, log = TRUE)
d_ocl <-     dmvnormOCL(samples, mean = mu, sigma = Sigma, log = TRUE)

max_diff_d <- max(abs(d_r - d_ocl))

message(sprintf("📊 [Test-Profil] dmvnormOCL max diff: %.8f", max_diff_d))
expect_true(max_diff_d < 1e-5)
samples <- samples[1:2000, ]

d_log_r   <- mvtnorm::dmvnorm(samples, mean = mu3, sigma = Sigma3, log = TRUE)
d_log_ocl <- dmvnormOCL(samples, mean = mu3, sigma = Sigma3, log = TRUE)

d_raw_r   <- mvtnorm::dmvnorm(samples, mean = mu3, sigma = Sigma3, log = FALSE)
d_raw_ocl <- dmvnormOCL(samples, mean = mu3, sigma = Sigma3, log = FALSE)

# Single vector (not passed as a matrix)
d_vec_r   <- mvtnorm::dmvnorm(samples[1, ], mean = mu3, sigma = Sigma3, log = TRUE)
d_vec_ocl <- dmvnormOCL(samples[1, ], mean = mu3, sigma = Sigma3, log = TRUE)

max_diff_d_log <- max(abs(d_log_r - d_log_ocl))
max_diff_d_raw <- max(abs(d_raw_r - d_raw_ocl))

message(sprintf("📊 [dmvnormOCL] max diff log: %.2e | raw: %.2e", max_diff_d_log, max_diff_d_raw))
expect_true(max_diff_d_log < 1e-5)
expect_true(max_diff_d_raw < 1e-5)
expect_true(abs(d_vec_r - d_vec_ocl) < 1e-5)

# =========================================================================
# ERROR HANDLING (Non-positive definite matrix & dimensional errors)
# =========================================================================
Sigma_bad <- matrix(c(1, 2, 2, 1), 2, 2) # Eigenwerte: 3 und -1 -> nicht positiv definit!
expect_true(is.nan(dmvnormOCL(c(0, 0), mean = c(0, 0), sigma = Sigma_bad)))

# Dimension mismatch should throw a real error

expect_error(dmvnormOCL(c(0, 0, 0), mean = c(0, 0), sigma = diag(2)))
