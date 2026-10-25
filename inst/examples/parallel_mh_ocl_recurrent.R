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

parallel_MH_sampler_recurrent <- oclFunction(
    signature = signature(
        n_samples    = "integer",
        n_chains     = "integer",
        n_recurrences = "integer",
        data_vector  = "numeric",
        mu_init      = "numeric",
        sigma_init   = "numeric"
    ),
    kernel_file     = "mh_recurrent_sampler.cl",
    interface_file  = "mh_recurrent_sampler.cpp",
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
window_width <- as.integer(samples / nchains)
nrecurrences <- 5  # cycle throuh window nrecurrences times
# means: we calcalute 100 x 10 million point but keep nly the last 10 million!
burnin  <- 100 # is now useless if nrecurrences > 1


start_time <- Sys.time()
results <- parallel_MH_sampler_recurrent(as.integer(samples), as.integer(nchains),
                                         as.integer(nrecurrences), data, mu_obs, sigma_obs)
end_time <- Sys.time()
run_time <- as.numeric(difftime(end_time, start_time, units = "secs"))

# Post-Processing & Splicing
matrix_mu     <- matrix(results$mu,    nrow = window_width, ncol = nchains)
matrix_sigma  <- matrix(results$sigma, nrow = window_width, ncol = nchains)
valid_indices <- (burnin + 1):window_width

final_chain_mu    <- as.vector(matrix_mu[valid_indices, ])
final_chain_sigma <- as.vector(matrix_sigma[valid_indices, ])

final_chain_mu    <- as.vector(matrix_mu)
final_chain_sigma <- as.vector(matrix_sigma)

# ==============================================================================
# 🚀 5. IN-MEMORY WINDOWING DIAGNOSTIK: MAP & X-ACHSEN REKALIBRIERUNG
# ==============================================================================
density_mu    <- density(final_chain_mu)
density_sigma <- density(final_chain_sigma)

map_mu    <- density_mu$x[which.max(density_mu$y)]
map_sigma <- density_sigma$x[which.max(density_sigma$y)]

cred_mu    <- quantile(final_chain_mu,    probs = c(0.025, 0.975))
cred_sigma <- quantile(final_chain_sigma, probs = c(0.025, 0.975))

cat("\n🏁 --- STATISTISCHE DIAGNOSTIK (v0.6.3+ Windowed) --- 🏁\n")
cat(" 🎯 MAP Schätzwert mu    (Modus) : ", round(map_mu, 4), "\n")
cat(" 📜 95% Cred. Interval mu        : [", round(cred_mu[1], 4), " , ", round(cred_mu[2], 4), "]\n")
cat("--------------------------------------------------\n")
cat(" 🎯 MAP Schätzwert sigma (Modus) : ", round(map_sigma, 4), "\n")
cat(" 📜 95% Cred. Interval sigma     : [", round(cred_sigma[1], 4), " , ", round(cred_sigma[2], 4), "]\n")
cat("==================================================\n")

# 🧠 HIER RECHNEN WIR DIE ECHTEN ITERATIONS-NUMMERN AUS!
# nrecurrences und samples_per_chain (window_width) müssen im R-Skript definiert sein!
total_chain_length <- nrecurrences * window_width
start_iteration    <- total_chain_length - window_width + 1

# Erzeuge die echten, historischen Iterations-Indizes für die X-Achse
true_iterations <- start_iteration:total_chain_length

df_chain <- data.frame(
  Iteration = rep(true_iterations, nchains),
  Chain     = as.factor(rep(1:nchains, each = window_width)),
  mu        = final_chain_mu,
  sigma     = final_chain_sigma
)

# Wir plotten das volle, ofenfrische Fenster ohne künstlichen Burnin-Abzug, 
# da das Burnin ohnehin in den vorigen Umläufen im VRAM im Kreis weggewischt wurde!
plot_df <- df_chain 

# ==============================================================================
# 🚀 6. ERWEITERTE TRACE- PLOTS MIT ECHTEN ITERATIONS-SCHRITTEN
# ==============================================================================
# Trace-Plot für mu (X-Achse startet nun z.B. bei 4001 und geht bis 5000)
plot_trace_mu <- ggplot(subset(plot_df, Chain %in% 1:5), aes(x = Iteration, y = mu, color = Chain)) +
  geom_line(alpha = 0.6) + 
  theme_minimal() + 
  labs(title = paste0("MCMC Trace Plots (Finale Epoche: ", start_iteration, " bis ", total_chain_length, ")"), 
       y = expression(mu), x = "Echte Iterations-Tiefe") + 
  theme(legend.position = "none")

# Trace-Plot für sigma
plot_trace_sigma <- ggplot(subset(plot_df, Chain %in% 1:5), aes(x = Iteration, y = sigma, color = Chain)) +
  geom_line(alpha = 0.6) + 
  theme_minimal() + 
  labs(y = expression(sigma), x = "Echte Iterations-Tiefe") + 
  theme(legend.position = "none")

cat("\n📊 Zeichne zeitbereinigte Diagramme im Grafikfenster...\n")
dev.new(noRStudioGD = TRUE)
grid.arrange(plot_trace_mu, plot_trace_sigma, ncol = 1)


## ==============================================================================
# 🚀 6. HISTOGRAMME ABSOLUT REISSFEST UND UNABHÄNGIG GEZEICHNET
# ==============================================================================

# Steriles Datenframe NUR für die Dichten (Völlig immun gegen X-Achsen-Verschiebungen!)
df_hist <- data.frame(
  mu    = final_chain_mu,
  sigma = final_chain_sigma
)

# Histogramm mu mit MAP und Intervallen
plot_hist_mu <- ggplot(df_hist, aes(x = mu)) +
  geom_histogram(aes(y = after_stat(density)), bins = 50, fill = "royalblue", alpha = 0.6) +
  geom_density(color = "darkblue", linewidth = 0.8) +
  geom_vline(xintercept = 5, color = "red", linetype = "dashed", linewidth = 0.8) + # Ziel
  geom_vline(xintercept = map_mu, color = "darkblue", linetype = "solid", linewidth = 0.8) + # MAP
  geom_vline(xintercept = cred_mu[1], color = "darkblue", linetype = "dotted", linewidth = 0.6) + # 2.5%
  geom_vline(xintercept = cred_mu[2], color = "darkblue", linetype = "dotted", linewidth = 0.6) + # 97.5%
  theme_minimal() +
  labs(title = "Posterior PDF (mit 95% Credibility Interval)", x = expression(mu), y = "density")

# Histogramm sigma mit MAP und Intervallen
plot_hist_sigma <- ggplot(df_hist, aes(x = sigma)) +
  geom_histogram(aes(y = after_stat(density)), bins = 50, fill = "#008080", alpha = 0.6) +
  geom_density(color = "#004d4d", linewidth = 0.8) +
  geom_vline(xintercept = 2, color = "red", linetype = "dashed", linewidth = 0.8) + # Ziel
  geom_vline(xintercept = map_sigma, color = "#004d4d", linetype = "solid", linewidth = 0.8) + # MAP
  geom_vline(xintercept = cred_sigma[1], color = "#004d4d", linetype = "dotted", linewidth = 0.6) + # 2.5%
  geom_vline(xintercept = cred_sigma[2], color = "#004d4d", linetype = "dotted", linewidth = 0.6) + # 97.5%
  theme_minimal() +
  labs(x = expression(sigma), y = "density")

cat("\n📊 Zeichne zeitbereinigte Diagramme im Grafikfenster...\n")

dev.new(noRStudioGD = TRUE)
grid.arrange(plot_hist_mu, plot_hist_sigma, ncol = 1)



