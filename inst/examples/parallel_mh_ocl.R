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

# ==============================================================================
# 🚀 5. STATISTISCHE DIAGNOSTIK: MAP & CREDIBILITY INTERVALS (95%)
# ==============================================================================
density_mu    <- density(final_chain_mu)
density_sigma <- density(final_chain_sigma)

# 🎯 MAP (Maximum A Posteriori) via empirischem Dichte-Maximum (Modus)
map_mu    <- density_mu$x[which.max(density_mu$y)]
map_sigma <- density_sigma$x[which.max(density_sigma$y)]

# 📜 95% Credibility Interval (Zweiseitiges Perzentil-Intervall)
cred_mu    <- quantile(final_chain_mu,    probs = c(0.025, 0.975))
cred_sigma <- quantile(final_chain_sigma, probs = c(0.025, 0.975))

cat("\n🏁 --- STATISTISCHE DIAGNOSTIK (v0.6.2+) --- 🏁\n")
cat(" 🎯 MAP Schätzwert mu    (Modus) : ", round(map_mu, 4), "\n")
cat(" 📜 95% Cred. Interval mu        : [", round(cred_mu[1], 4), " , ", round(cred_mu[2], 4), "]\n")
cat("--------------------------------------------------\n")
cat(" 🎯 MAP Schätzwert sigma (Modus) : ", round(map_sigma, 4), "\n")
cat(" 📜 95% Cred. Interval sigma     : [", round(cred_sigma[1], 4), " , ", round(cred_sigma[2], 4), "]\n")
cat("==================================================\n")

df_chain <- data.frame(
  Iteration = rep(valid_indices, nchains),
  Chain     = as.factor(rep(1:nchains, each = length(valid_indices))),
  mu        = final_chain_mu,
  sigma     = final_chain_sigma
)

# ==============================================================================
# 🚀 6. POSTERIOR-OUTPUTS & DIAGRAMME MIT STAT-LINIEN
# ==============================================================================
# Trace-Plots (unverändert für Ketten 1:5)
plot_trace_mu <- ggplot(subset(df_chain, Chain %in% 1:5), aes(x = Iteration, y = mu, color = Chain)) +
  geom_line(alpha = 0.6) + theme_minimal() + labs(title = "MCMC Trace Plots", y = expression(mu)) + theme(legend.position = "none")

plot_trace_sigma <- ggplot(subset(df_chain, Chain %in% 1:5), aes(x = Iteration, y = sigma, color = Chain)) +
  geom_line(alpha = 0.6) + theme_minimal() + labs(y = expression(sigma)) + theme(legend.position = "none")

# Histogramm mu mit MAP und Intervallen
plot_hist_mu <- ggplot(df_chain, aes(x = mu)) +
  geom_histogram(aes(y = ..density..), bins = 50, fill = "royalblue", alpha = 0.6) + 
  geom_density(color = "darkblue", size = 0.8) +
  geom_vline(xintercept = 5, color = "red", linetype = "dashed", size = 0.8) + # Wahres Ziel
  geom_vline(xintercept = map_mu, color = "darkblue", linetype = "dotted", size = 0.8) + # MAP
  geom_vline(xintercept = cred_mu[1], color = "darkblue", linetype = "dotted", size = 0.6) + # 2.5% Bound
  geom_vline(xintercept = cred_mu[2], color = "darkblue", linetype = "dotted", size = 0.6) + # 97.5% Bound
  theme_minimal() + labs(title = "Posterior PDF (mit 95% Credibility Interval und MAP Schaetzer)", x = expression(mu))

# Histogramm sigma mit MAP und Intervallen
plot_hist_sigma <- ggplot(df_chain, aes(x = sigma)) +
  geom_histogram(aes(y = ..density..), bins = 50, fill = "#008080", alpha = 0.6) + 
  geom_density(color = "#004d4d", size = 0.8) +
  geom_vline(xintercept = 2, color = "red", linetype = "dashed", size = 0.8) + # Wahres Ziel
  geom_vline(xintercept = map_sigma, color = "#004d4d", linetype = "dotted", size = 0.8) + # MAP
  geom_vline(xintercept = cred_sigma[1], color = "#004d4d", linetype = "dotted", size = 0.6) + # 2.5% Bound
  geom_vline(xintercept = cred_sigma[2], color = "#004d4d", linetype = "dotted", size = 0.6) + # 97.5% Bound
  theme_minimal() + labs(x = expression(sigma))

cat("\n📊 Zeichne erweiterte Diagramme im Grafikfenster...\n")

dev.new(noRStudioGD = TRUE)
grid.arrange(plot_trace_mu, plot_trace_sigma, ncol = 1)

dev.new(noRStudioGD = TRUE)
grid.arrange(plot_hist_mu, plot_hist_sigma, ncol = 1)
