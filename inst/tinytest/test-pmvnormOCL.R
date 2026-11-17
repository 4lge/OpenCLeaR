source("setup.R", local = TRUE)

if (!isTRUE(getOption("OpenCLeaR.initialized"))) exit_file("no OpenCL device available")

# 📊 TEST D-FUNKTION (Dichte-Abgleich)
mu3 <- c(1, 2, 3)
Sigma3 <- matrix(c(1,    0.5,  0.25,
                   0.5,  1,    0.5,
                   0.25, 0.5,  1), nrow = 3, ncol = 3)

samples <- rmvnormOCL(200000L, mean = mu3, sigma = Sigma3)

expect_equal(dim(samples), c(200000L, 3L))

# 3a. Gemischte Grenzen (-Inf, endlich, +Inf)
p_r_1   <- as.numeric(mvtnorm::pmvnorm(lower = c(-Inf, 1, 1.5), upper = c(2, 3.5, Inf), mean = mu3, sigma = Sigma3))
p_ocl_1 <- as.numeric(pmvnormOCL(lower = c(-Inf, 1, 1.5), upper = c(2, 3.5, Inf), mean = mu3, sigma = Sigma3, n = 4e6L))

# 3b. Vollständig einseitig (-Inf bis upper)
p_r_2   <- as.numeric(mvtnorm::pmvnorm(lower = rep(-Inf, 3), upper = c(1.5, 2.5, 3.5), mean = mu3, sigma = Sigma3))
p_ocl_2 <- as.numeric(pmvnormOCL(lower = rep(-Inf, 3), upper = c(1.5, 2.5, 3.5), mean = mu3, sigma = Sigma3, n = 4e6L))

# 3c. Höherdimensional (dim = 8) zum Prüfen der Schleifen & Speicher-Offsets
dim8 <- 8L
mu8 <- seq(-1, 1, length.out = dim8)
Sigma8 <- 0.5 ^ abs(outer(1:dim8, 1:dim8, "-")) # AR(1)-Korrelationsmatrix
p_r_8   <- as.numeric(mvtnorm::pmvnorm(lower = rep(-1.5, dim8), upper = rep(1.5, dim8), mean = mu8, sigma = Sigma8))
p_ocl_8 <- as.numeric(pmvnormOCL(lower = rep(-1.5, dim8), upper = rep(1.5, dim8), mean = mu8, sigma = Sigma8, n = 4e6L))

max_diff_p <- max(abs(c(p_r_1 - p_ocl_1, p_r_2 - p_ocl_2, p_r_8 - p_ocl_8)))
message(sprintf("📊 [pmvnormOCL] max diff (3D + 8D): %.6f", max_diff_p))
expect_true(max_diff_p < 1e-3)

# =========================================================================
# 5. FEHLERBEHANDLUNG (Nicht positiv definite Matrix & Dimensionsfehler)
# =========================================================================
Sigma_bad <- matrix(c(1, 2, 2, 1), 2, 2) # Eigenwerte: 3 und -1 -> nicht positiv definit!
expect_true(is.nan(as.numeric(pmvnormOCL(lower = c(-1, -1), upper = c(1, 1), mean = c(0, 0), sigma = Sigma_bad))))
