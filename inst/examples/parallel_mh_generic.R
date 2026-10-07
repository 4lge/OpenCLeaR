library(inline)
library(OpenCLeaR)
library(ggplot2)
library(gridExtra)

# ==============================================================================
# 🚀 1. DER REINE, WINZIGE LOGIK-KERNEL (Exakt so klein wie Ihr Teil 1/1)
# ==============================================================================
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
    
    // 🔐 1. Zustand des Mersenne-Twisters als Array deklarieren
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
        
        // Blind und ultraschnell aus Ihrem installierten Core abrufen!
        real_t mu_proposal    = rnorm(mu_current, prop_sd_mu, &idx, mt);
        real_t sigma_proposal = rnorm(sigma_current, prop_sd_sigma, &idx, mt);
        
        if (sigma_proposal <= (real_t)0.01) { 
            out_mu[offset + t] = mu_current;
            out_sigma[offset + t] = sigma_current;
            continue;
        }
        
        // --- 1. Log-Posterior des Vorschlags berechnen (Python-Priors: 0.01 und 1.0/0.01) ---
        real_t log_prior_prop = log(normal_pdf(mu_proposal, (real_t)0.0, (real_t)10.0)) + 
                                log(invgamma_pdf(sigma_proposal, (real_t)0.01, (real_t)1.0/(real_t)0.01));
        real_t log_lik_prop = (real_t)0.0;
        for(int d = 0; d < data_len; ++d) {
            log_lik_prop += log(normal_pdf(data[d], mu_proposal, sigma_proposal));
        }
        real_t log_post_prop = log_prior_prop + log_lik_prop;
        
        // --- 2. Log-Posterior des aktuellen Zustands berechnen ---
        real_t log_prior_curr = log(normal_pdf(mu_current, (real_t)0.0, (real_t)10.0)) + 
                                log(invgamma_pdf(sigma_current, (real_t)0.01, (real_t)1.0/(real_t)0.01));
        real_t log_lik_curr = (real_t)0.0;
        for(int d = 0; d < data_len; ++d) {
            log_lik_curr += log(normal_pdf(data[d], mu_current, sigma_current));
        }
        real_t log_post_curr = log_prior_curr + log_lik_curr;
        
        // --- 3. Akzeptanz-Schritt ---
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

# ==============================================================================
# 🚀 2. DAS RCP-INTERFACE (Nativ und clean, KEIN get_opencl_c_code hier drin!)
# ==============================================================================
interface_code <- "

    int total_samples = as<int>(n_samples);
    int chains        = as<int>(n_chains);
    int samples_per_chain = total_samples / chains;

    NumericVector r_data(data_vector);
    int data_len = r_data.size();
    int total_output_size = chains * samples_per_chain;

    NumericVector out_mu(total_output_size);
    NumericVector out_sigma(total_output_size);

    Environment e = Environment::global_env();
    std::vector<int> r_seed = e[\".Random.seed\"];
    int base_seed = r_seed[r_seed[1] + 1];

    // Hardware-Puffer füttern (device wird vollautomatisch von generateInlineCL injiziert!)
    Memory<real_t> GpuData(*device, data_len);
    Memory<real_t> GpuMu(*device, total_output_size);
    Memory<real_t> GpuSigma(*device, total_output_size);
    Memory<int>    GpuSeeds(*device, chains);

    for(int i=0; i<data_len; ++i) GpuData[i] = (real_t)r_data[i];
    for(int i=0; i<chains; ++i)   GpuSeeds[i] = base_seed + (i * 777);

    GpuData.write_to_device();
    GpuSeeds.write_to_device();

    Kernel mh_kernel(*device, chains, \"mh_sampler_kernel\", 
                     GpuMu, GpuSigma, GpuData, data_len, samples_per_chain,
                     as<real_t>(mu_init), as<real_t>(sigma_init), 0.05, 0.05, GpuSeeds);

    // 🔥 FEUER FREI AUF DER GPU 🔥
    mh_kernel.run();

    GpuMu.read_from_device();
    GpuSigma.read_from_device();

    for(int i=0; i<total_output_size; ++i) {
        out_mu[i]    = GpuMu[i];
        out_sigma[i] = GpuSigma[i];
    }

    Function f(\"runif\"); f(1);

    return List::create(
        _[\"mu\"]    = out_mu,
        _[\"sigma\"] = out_sigma
    );
"

# ==============================================================================
# 🚀 3. DER GENERISCHE KOPPLUNGS-BEFEHL (v0.5.0 Zündung)
# ==============================================================================
cat("⏳ Kompiliere GPGPU-Laufzeit-Objekt via generateInlineCL...\n")

parallel_MH_sampler <- generateInlineCL(
    signature = signature(
        n_samples   = "integer",
        n_chains    = "integer",
        data_vector = "numeric",
        mu_init     = "numeric",
        sigma_init  = "numeric"
    ),
    kernel_code = MH_kernel_string,
    body        = interface_code
)

# ==============================================================================
# 🚀 4. STRESSTEST-DATEN & ULTRA-AUSFÜHRUNG (10 Millionen Punkte!)
# ==============================================================================
set.seed(444)
data <- rnorm(1000, mean = 5, sd = 2)
mu_obs    <- mean(data)
sigma_obs <- sd(data)

samples <- 100000000L # 100 Millionen Punkte!
nchains <- 10000L    # 10.000 parallele Ketten!
burnin  <- 200L
samples_per_chain <- as.integer(samples / nchains)
if(burnin>samples_per_chain) stop("burnin too large")
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


