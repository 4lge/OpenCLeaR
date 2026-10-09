library(inline)
library(OpenCLeaR)
library(ggplot2)
library(gridExtra)

# ==============================================================================
# 🚀 1. DER REINE, WINZIGE LOGIK-KERNEL (Exakt so klein wie Ihr Teil 1/1)
# ==============================================================================

# ==============================================================================
# 🚀 2. DAS RCP-INTERFACE (Nativ und clean, KEIN get_opencl_c_code hier drin!)
# ==============================================================================


# ==============================================================================
# 🚀 3. DER GENERISCHE KOPPLUNGS-BEFEHL (v0.5.0 Zündung)
# ==============================================================================
cat("⏳ Kompiliere GPGPU-Laufzeit-Objekt via oclFunction...\n")

parallel_MH_sampler <- oclFunction(
    signature = signature(
        n_samples   = "integer",
        n_chains    = "integer",
        data_vector = "numeric",
        mu_init     = "numeric",
        sigma_init  = "numeric"
    ),
    kernel_file     = "mh_sampler.cl",
    interface_file  = "mh_sampler.cpp",
    force_float = T
)

# ==============================================================================
# 🚀 4. STRESSTEST-DATEN & ULTRA-AUSFÜHRUNG (10 Millionen Punkte!)
# ==============================================================================
set.seed(444)
data <- rnorm(1000, mean = 5, sd = 2)
mu_obs    <- mean(data)
sigma_obs <- sd(data)

samples <- 10000000L # 10 Millionen Punkte!
nchains <- 10000L    # 10.000 parallele Ketten!
burnin  <- 200L
samples_per_chain <- as.integer(samples / nchains)

start_time <- Sys.time()
results <- parallel_MH_sampler(as.integer(samples), as.integer(nchains), data, mu_obs, sigma_obs)
end_time <- Sys.time()
run_time <- as.numeric(difftime(end_time, start_time, units = "secs"))

# Post-Processing & Splicing
matrix_mu     <- matrix(results$mu,    nrow = samples_per_chain, ncol = nchains)
matrix_sigma  <- matrix(results$sigma, nrow = samples_per_chain, ncol = nchains)
valid_indices <- (burnin + 1):samples_per_chain

final_chain_mu    <- as.vector(matrix_mu[valid_indices, ])
final_chain_sigma <- as.vector(matrix_sigma[valid_indices, ])

# ==============================================================================mh/
# 🚀 5. POSTERIOR-OUTPUTS & DIAGRAMME
# ==============================================================================
cat("\n🏁 --- BENCHMARK ERGEBNISSE (v0.5.0 Generic) --- 🏁\n")
cat(" ⏱️ GPGPU Run Time : ", round(run_time, 5), " Sekund(en)!\n")
cat(" Schätzwert mu    (Soll ~5) : ", round(mean(final_chain_mu), 4), "\n")
cat(" Schätzwert sigma (Soll ~2) : ", round(mean(final_chain_sigma), 4), "\n")
cat("--------------------------------------------------\n")

df_chain <- data.frame(
  Iteration = rep(valid_indices, nchains),
  Chain     = as.factor(rep(1:nchains, each = length(valid_indices))),
  mu        = final_chain_mu,
  sigma     = final_chain_sigma
)

plot_hist_mu <- ggplot(df_chain, aes(x = mu)) +
  geom_histogram(aes(y = after_stat(density)), bins = 50, fill = "royalblue", alpha = 0.6, color = "white") +
  geom_density(color = "darkblue", linewidth = 1) + 
  geom_vline(xintercept = 5, color = "red", linetype = "dashed", linewidth = 1) +
  theme_minimal() + labs(title = "Posterior PDF via generateInlineCL", x = expression(mu))

plot_hist_sigma <- ggplot(df_chain, aes(x = sigma)) +
  geom_histogram(aes(y = after_stat(density)), bins = 50, fill = "#008080", alpha = 0.6, color = "white") +
  geom_density(color = "#004d4d", linewidth = 1) + 
  geom_vline(xintercept = 2, color = "red", linetype = "dashed", linewidth = 1) +
  theme_minimal() + labs(x = expression(sigma))

dev.new(noRStudioGD = TRUE)
grid.arrange(plot_hist_mu, plot_hist_sigma, ncol = 1)


