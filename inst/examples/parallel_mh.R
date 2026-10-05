# ==============================================================================
# OpenCLeaR: Paralleler Metropolis-Hastings GPGPU-Sampler
# ==============================================================================
require(inline)
require(OpenCLeaR)
require(ggplot2)
require(gridExtra)

# --- SCHRITT 1: DER OPENCL-LOGIK-KERNEL ALS STRING ---

MH_kernel_string <- "
__kernel void mh_sampler_kernel(__global real_t* out_mu, 
                                __global real_t* out_sigma,
                                __global const real_t* data, 
                                const int data_len,
                                const int samples_per_chain,
                                const real_t mu_init,
                                const real_t sigma_init,
                                const real_t prop_sd_mu,
                                const real_t prop_sd_sigma,
                                __global int* seed_array) {
    
    int gid = get_global_id(0);
    int offset = gid * samples_per_chain;
    
    // 🔐 1. Den exakt gleichen Mersenne-Twister-Zustand wie im Core initialisieren
    uint mt[624];
    int idx = 624;
    mt[0] = seed_array[gid] + gid;
    for (int i = 1; i < 624; ++i) {
        mt[i] = (181243 * (mt[i - 1] ^ (mt[i - 1] >> 30)) + i);
    }
    
    real_t mu_current = mu_init;
    real_t sigma_current = sigma_init;
    
    out_mu[offset] = mu_current;
    out_sigma[offset] = sigma_current;
    
    // 🔄 Der serielle MCMC-Loop innerhalb des parallelen GPU-Threads
    for (int t = 1; t < samples_per_chain; ++t) {
        
        // 🚀 Direkt Ihr eingebautes 'rnorm' für den Random Walk aufrufen
        real_t mu_proposal    = rnorm(mu_current, prop_sd_mu, &idx, mt);
        real_t sigma_proposal = rnorm(sigma_current, prop_sd_sigma, &idx, mt);
        
        if (sigma_proposal <= (real_t)0.0) { // Gültigkeitsbereich für Sigma schützen
            out_mu[offset + t] = mu_current;
            out_sigma[offset + t] = sigma_current;
            continue;
        }
        
        // --- 1. Log-Posterior des Vorschlags berechnen (Normal + frisch eingebautes invgamma_pdf) ---
        real_t log_prior_prop = log(normal_pdf(mu_proposal, (real_t)0.0, (real_t)10.0)) + 
                                log(invgamma_pdf(sigma_proposal, (real_t)0.01, (real_t)1.0/(real_t)0.0));
        real_t log_lik_prop = (real_t)0.0;
        for(int d = 0; d < data_len; ++d) {
            log_lik_prop += log(normal_pdf(data[d], mu_proposal, sigma_proposal));
        }
        real_t log_post_prop = log_prior_prop + log_lik_prop;
        
        // --- 2. Log-Posterior des aktuellen Zustands berechnen ---
        real_t log_prior_curr = log(normal_pdf(mu_current, (real_t)0.0, (real_t)10.0)) + 
                                log(invgamma_pdf(sigma_current, (real_t)0.0, (real_t)1.0/(real_t)0.0));
        real_t log_lik_curr = (real_t)0.0;
        for(int d = 0; d < data_len; ++d) {
            log_lik_curr += log(normal_pdf(data[d], mu_current, sigma_current));
        }
        real_t log_post_curr = log_prior_curr + log_lik_curr;
        
        // --- 3. Akzeptanz-Schritt via mt_rand_01() aus Ihrer libkernel.cpp ---
        real_t p_accept = min((real_t)1.0, exp(log_post_prop - log_post_curr));
        
        if (mt_rand_01(&mt[0], &idx, mt) < p_accept) {
            mu_current = mu_proposal;
            sigma_current = sigma_proposal;
        }
        
        out_mu[offset + t] = mu_current;
        out_sigma[offset + t] = sigma_current;
    }
}
"

# --- SCHRITT 3: DER INLINE-COMPILER INTERFACE-BAU ---

parallel_MH_sampler <- inline::cxxfunction(signature(
    n_samples        = "integer",
    n_chains         = "integer",
    data_vector      = "numeric",
    mu_init          = "numeric",
    sigma_init       = "numeric"
), paste0("
    using namespace backend;

    int total_samples = as<int>(n_samples);
    int chains        = as<int>(n_chains);
    int samples_per_chain = total_samples / chains;

    NumericVector r_data(data_vector);
    int data_len = r_data.size();

    Device* device = const_cast<Device*>(&getActiveDeviceFromBackend());

    // Fliegend direkt aus dem RAM-String im Grafiktreiber kompilieren!
    device->set_kernel_source(R\"(", MH_kernel_string, ")\");

    device->compile_kernel();

    int total_output_size = chains * samples_per_chain;
    NumericVector out_mu(total_output_size);
    NumericVector out_sigma(total_output_size);

    Environment e = Environment::global_env();
    std::vector<int> r_seed = e[\".Random.seed\"];
    int base_seed = r_seed[r_seed[1] + 1];

    // Hardware-Puffer füttern (FP64-Weiche berücksichtigt)
    Memory<double> GpuData(*device, data_len);
    Memory<double> GpuMu(*device, total_output_size);
    Memory<double> GpuSigma(*device, total_output_size);
    Memory<int>    GpuSeeds(*device, chains);

    for(int i=0; i<data_len; ++i) GpuData[i] = (double)r_data[i];
    for(int i=0; i<chains; ++i)   GpuSeeds[i] = base_seed + (i * 777);

    GpuData.write_to_device();
    GpuSeeds.write_to_device();

    Kernel mh_kernel(*device, chains, \"mh_sampler_kernel\", 
GpuMu,
GpuSigma,
GpuData,
data_len,
samples_per_chain,
as<double>(mu_init),
as<double>(sigma_init),
0.05, // prop_sd_mu
0.05, // prop_sd_sigma
GpuSeeds);

    // 🔥 FEUER FREI AUF DER GPU 🔥
    mh_kernel.run();

    GpuMu.read_from_device();
    GpuSigma.read_from_device();

    for(int i=0; i<total_output_size; ++i) {
        out_mu[i]    = GpuMu[i];
        out_sigma[i] = GpuSigma[i];
    }

    Function f(\"runif\");
    f(1);

    return List::create(
        _[\"mu\"]    = out_mu,
        _[\"sigma\"] = out_sigma
    );
"), plugin = "OpenCLeaR", verbose = TRUE)

# --- SCHRITT 3: DATA-SETUP & EXECUTION RUN ---

set.seed(444)
data <- rnorm(1000, mean = 5, sd = 2)
mu_obs    <- mean(data)
sigma_obs <- sd(data)

samples <- 10000000L # 🚀 BRUTALE ERHÖHUNG: 10 Millionen Gesamt-Samples!
nchains <- 10000L    # 🚀 MASSIVE PARALLELITÄT: 10.000 Ketten simultan auf den GPU-Cores!
burnin  <- 200L      # Jede Kette rechnet 1.000 Schritte, die ersten 200 fliegen weg.

samples_per_chain <- as.integer(samples / nchains)

start_time <- Sys.time()
results <- parallel_MH_sampler(as.integer(samples), as.integer(nchains), data, mu_obs, sigma_obs)
end_time <- Sys.time()
run_time <- as.numeric(difftime(end_time, start_time, units = "secs"))

# --- SCHRITT 4: MATRIX-SPLICING & POST-PROCESSING ---
matrix_mu    <- matrix(results$mu,    nrow = samples_per_chain, ncol = nchains)
matrix_sigma <- matrix(results$sigma, nrow = samples_per_chain, ncol = nchains)
valid_indices <- (burnin + 1):samples_per_chain

final_chain_mu    <- as.vector(matrix_mu[valid_indices, ])
final_chain_sigma <- as.vector(matrix_sigma[valid_indices, ])

# --- SCHRITT 5: PLOTS GENERIEREN (AUS TEIL 3/3 ADAPTIERT) ---
df_chain <- data.frame(
  Iteration = rep(valid_indices, nchains),
  Chain     = as.factor(rep(1:nchains, each = length(valid_indices))),
  mu        = final_chain_mu,
  sigma     = final_chain_sigma
)

# Trace-Plots
plot_trace_mu <- ggplot(subset(df_chain, Chain %in% 1:5), aes(x = Iteration, y = mu, color = Chain)) +
  geom_line(alpha = 0.6) + theme_minimal() + labs(title = "Trace Plots", y = expression(mu)) + theme(legend.position = "none")
plot_trace_sigma <- ggplot(subset(df_chain, Chain %in% 1:5), aes(x = Iteration, y = sigma, color = Chain)) +
  geom_line(alpha = 0.6) + theme_minimal() + labs(y = expression(sigma)) + theme(legend.position = "none")

# Histogramme
plot_hist_mu <- ggplot(df_chain, aes(x = mu)) +
  geom_histogram(aes(y = ..density..), bins = 50, fill = "royalblue", alpha = 0.6) + geom_density(color = "darkblue") +
  geom_vline(xintercept = 5, color = "red", linetype = "dashed") + theme_minimal() + labs(title = "Posterior PDF", x = expression(mu))
plot_hist_sigma <- ggplot(df_chain, aes(x = sigma)) +
  geom_histogram(aes(y = ..density..), bins = 50, fill = "#008080", alpha = 0.6) + geom_density(color = "#004d4d") +
  geom_vline(xintercept = 2, color = "red", linetype = "dashed") + theme_minimal() + labs(x = expression(sigma))


cat("\n📊 Zeichne Diagramme im Grafikfenster...\n")

# 1. Die Traceplots (Ketten-Konvergenz) auf den Schirm jagen
dev.new(noRStudioGD = TRUE) # Öffnet ein frisches, autarkes Grafikfenster
grid.arrange(plot_trace_mu, plot_trace_sigma, ncol = 1)

# 2. Die Histogramme (Posterior-Glockenkurven) auf den Schirm jagen
dev.new(noRStudioGD = TRUE) # Öffnet ein zweites Fenster für die PDFs
grid.arrange(plot_hist_mu, plot_hist_sigma, ncol = 1)

cat("\n✨ Alle Berechnungen und Visualisierungen erfolgreich abgeschlossen!\n")
cat("🛑 [PAUSE] Drücken Sie [ENTER] in der Konsole, um die Plots zu schließen... ")


# Ausgabe der Schätzwerte
cat("\n📊 --- BAYESIANISCHE POSTERIOR-SCHÄTZUNG --- 📊\n")
cat(" ⏱️ GPGPU Run Time       : ", round(run_time, 5), " Sekund(en)!\n")
cat(" Erwartetes mu    (Soll: ~5) : ", round(mean(final_chain_mu), 4), "\n")
cat(" Erwartetes sigma (Soll: ~2) : ", round(mean(final_chain_sigma), 4), "\n")
cat("================================================\n")

