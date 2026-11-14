## ----setup, include=FALSE-----------------------------------------------------
knitr::opts_chunk$set(echo = TRUE, warning = FALSE, message = FALSE)
library(parallel)
library(Rcpp)
library(RcppParallel)
library(inline)
library(OpenCLeaR)
library(ggplot2)
library(gridExtra)


## clinfo -l

## ----devices------------------------------------------------------------------
GetDeviceList()


## ----data_generation----------------------------------------------------------
# Define simulation configurations: 1,000 chains simulating 1,000 steps each
total_samples <- 1000000L    
num_chains <- 1000L       
samples_per_chain <- as.integer(total_samples / num_chains)

set.seed(444)
raw_data <- rnorm(1000, mean = 5, sd = 2)
mu_empirical <- mean(raw_data)
sigma_empirical <- sd(raw_data)

# Extract a stable random seed to synchronize the initial states of the C++ and OpenCL engines
rng_state <- get(".Random.seed", envir = .GlobalEnv)
seed_base <- as.integer(rng_state[2])


## ----engine_pure_r------------------------------------------------------------
run_mh_pure_r <- function(samples_per_chain, num_chains, raw_data, mu_init, sigma_init, seed_base) {
  total_size <- num_chains * samples_per_chain
  extracted_mu <- numeric(total_size)
  extracted_sigma <- numeric(total_size)
  
  for (c in 1:num_chains) {
    chain_offset <- (c - 1) * samples_per_chain
    set.seed(seed_base + ((c - 1) * 777))
    mu_current <- mu_init
    sigma_current <- sigma_init
    extracted_mu[chain_offset + 1] <- mu_current
    extracted_sigma[chain_offset + 1] <- sigma_current
    
    for (t in 2:samples_per_chain) {
      mu_proposal <- rnorm(1, mean = mu_current, sd = 0.05)
      sigma_proposal <- rnorm(1, mean = sigma_current, sd = 0.05)
      
      if (sigma_proposal <= 0.01) {
        extracted_mu[chain_offset + t] <- mu_current
        extracted_sigma[chain_offset + t] <- sigma_current
        next
      }
      
      log_prior_prop <- dnorm(mu_proposal, 0.0, 10.0, log = TRUE) + 
                        dgamma(1 / sigma_proposal, shape = 0.01, scale = 1 / 0.01, log = TRUE)
      log_lik_prop <- sum(dnorm(raw_data, mu_proposal, sigma_proposal, log = TRUE))
      
      log_prior_curr <- dnorm(mu_current, 0.0, 10.0, log = TRUE) + 
                        dgamma(1 / sigma_current, shape = 0.01, scale = 1 / 0.01, log = TRUE)
      log_lik_curr <- sum(dnorm(raw_data, mu_current, sigma_current, log = TRUE))
      
      if (log(runif(1)) < ((log_prior_prop + log_lik_prop) - (log_prior_curr + log_lik_curr))) {
        mu_current <- mu_proposal
        sigma_current <- sigma_proposal
      }
      extracted_mu[chain_offset + t] <- mu_current
      extracted_sigma[chain_offset + t] <- sigma_current
    }
  }
  return(list(mu = extracted_mu, sigma = extracted_sigma))
}


## ----engine_mclapply----------------------------------------------------------
run_mh_r_subprocesses <- function(samples_per_chain, num_chains, raw_data, mu_init, sigma_init, seed_base) {
  cores_to_use <- parallel::detectCores()
  
  chain_results <- parallel::mclapply(1:num_chains, function(c) {
    set.seed(seed_base + ((c - 1) * 777))
    mu_curr <- mu_init
    sigma_curr <- sigma_init
    m_mu <- numeric(samples_per_chain)
    m_sigma <- numeric(samples_per_chain)
    m_mu[1] <- mu_curr
    m_sigma[1] <- sigma_curr
    
    for (t in 2:samples_per_chain) {
      mu_prop <- rnorm(1, mean = mu_curr, sd = 0.05)
      sigma_prop <- rnorm(1, mean = sigma_curr, sd = 0.05)
      
      if (sigma_prop <= 0.01) { 
        m_mu[t] <- mu_curr
        m_sigma[t] <- sigma_curr
        next 
      }
      
      log_prior_prop <- dnorm(mu_prop, 0.0, 10.0, log = TRUE) + 
                        dgamma(1 / sigma_prop, shape = 0.01, scale = 1 / 0.01, log = TRUE) + 
                        sum(dnorm(raw_data, mu_prop, sigma_prop, log = TRUE))
                        
      log_prior_curr <- dnorm(mu_curr, 0.0, 10.0, log = TRUE) + 
                        dgamma(1 / sigma_curr, shape = 0.01, scale = 1 / 0.01, log = TRUE) + 
                        sum(dnorm(raw_data, mu_curr, sigma_curr, log = TRUE))
                        
      if (log(runif(1)) < (log_prior_prop - log_prior_curr)) { 
        mu_curr <- mu_prop
        sigma_curr <- sigma_prop 
      }
      m_mu[t] <- mu_curr
      m_sigma[t] <- sigma_curr
    }
    return(list(mu = m_mu, sigma = m_sigma))
  }, mc.cores = cores_to_use)
  
  extracted_mu <- unlist(lapply(chain_results, function(x) x$mu))
  extracted_sigma <- unlist(lapply(chain_results, function(x) x$sigma))
  return(list(mu = extracted_mu, sigma = extracted_sigma))
}


## ----engine_rcpp--------------------------------------------------------------
Rcpp::sourceCpp(code = '
#include <RcppParallel.h>
#include <Rcpp.h>
#include <cmath>
#include <random>

// [[Rcpp::plugins(cpp17)]]
// [[Rcpp::depends(RcppParallel)]]

// Native serial CPU engine (1 Thread)
// [[Rcpp::export]]
Rcpp::List run_mh_rcpp_serial(int total_samples, int num_chains, Rcpp::NumericVector raw_data, double mu_init, double sigma_init, int seed_base) {
    int samples_per_chain = total_samples / num_chains;
    int data_len = raw_data.size();
    Rcpp::NumericVector extracted_mu(num_chains * samples_per_chain);
    Rcpp::NumericVector extracted_sigma(num_chains * samples_per_chain);

    for (int c = 0; c < num_chains; ++c) {
        int chain_offset = c * samples_per_chain;
        std::mt19937 cpu_mt(seed_base + (c * 777));
        std::normal_distribution<double> cpu_normal(0.0, 0.05);
        std::uniform_real_distribution<double> cpu_uniform(0.0, 1.0);
        
        double mu_current = mu_init; 
        double sigma_current = sigma_init;
        extracted_mu[chain_offset] = mu_current; 
        extracted_sigma[chain_offset] = sigma_current;

        for (int t = 1; t < samples_per_chain; ++t) {
            double mu_proposal    = mu_current + cpu_normal(cpu_mt); 
            double sigma_proposal = sigma_current + cpu_normal(cpu_mt);
            
            if (sigma_proposal <= 0.01) { 
                extracted_mu[chain_offset + t] = mu_current; 
                extracted_sigma[chain_offset + t] = sigma_current; 
                continue; 
            }
            
            double log_prior_prop = R::dnorm(mu_proposal, 0.0, 10.0, true) + R::dgamma(1.0 / sigma_proposal, 0.01, 1.0 / 0.01, true);
            for (int d = 0; d < data_len; ++d) log_prior_prop += R::dnorm(raw_data[d], mu_proposal, sigma_proposal, true);
            
            double log_prior_curr = R::dnorm(mu_current, 0.0, 10.0, true) + R::dgamma(1.0 / sigma_current, 0.01, 1.0 / 0.01, true);
            for (int d = 0; d < data_len; ++d) log_prior_curr += R::dnorm(raw_data[d], mu_current, sigma_current, true);
            
            if (std::log(cpu_uniform(cpu_mt)) < (log_prior_prop - log_prior_curr)) { 
                mu_current = mu_proposal; 
                sigma_current = sigma_proposal; 
            }
            extracted_mu[chain_offset + t] = mu_current; 
            extracted_sigma[chain_offset + t] = sigma_current;
        }
    }
    return Rcpp::List::create(Rcpp::_["mu"] = extracted_mu, Rcpp::_["sigma"] = extracted_sigma);
}

// Multi-threaded CPU engine worker (Intel TBB)
struct ParallelMCMCSampler : public RcppParallel::Worker {
    int samples_per_chain; int data_len; RcppParallel::RVector<double> raw_data;
    double mu_init; double sigma_init; int seed_base;
    RcppParallel::RVector<double> extracted_mu; RcppParallel::RVector<double> extracted_sigma;
    
    ParallelMCMCSampler(int s, int d, Rcpp::NumericVector dv, double mi, double si, int bs, Rcpp::NumericVector om, Rcpp::NumericVector os)
        : samples_per_chain(s), data_len(d), raw_data(dv), mu_init(mi), sigma_init(si), seed_base(bs), extracted_mu(om), extracted_sigma(os) {}

    inline double thread_log_normal_pdf(double x, double m, double s) const { return -0.5 * std::log(2.0 * M_PI) - std::log(s) - 0.5 * std::pow((x - m) / s, 2.0); }
    inline double thread_log_invgamma_pdf(double x, double a, double b) const { return a * std::log(b) - std::lgamma(a) - (a + 1.0) * std::log(x) - (b / x); }

    void operator()(std::size_t begin_chain, std::size_t end_chain) {
        for (std::size_t c = begin_chain; c < end_chain; ++c) {
            int chain_offset = c * samples_per_chain;
            std::mt19937 cpu_mt(seed_base + (c * 777));
            std::normal_distribution<double> cpu_normal(0.0, 0.05);
            std::uniform_real_distribution<double> cpu_uniform(0.0, 1.0);
            
            double mu_current = mu_init; double sigma_current = sigma_init;
            extracted_mu[chain_offset] = mu_current; extracted_sigma[chain_offset] = sigma_current;

            for (int t = 1; t < samples_per_chain; ++t) {
                double mu_proposal    = mu_current + cpu_normal(cpu_mt); 
                double sigma_proposal = sigma_current + cpu_normal(cpu_mt);
                if (sigma_proposal <= 0.01001) { extracted_mu[chain_offset + t] = mu_current; extracted_sigma[chain_offset + t] = sigma_current; continue; }
                
                double log_prior_prop = thread_log_normal_pdf(mu_proposal, 0.0, 10.0) + thread_log_invgamma_pdf(sigma_proposal, 0.01, 1.0 / 0.01);
                for (int d = 0; d < data_len; ++d) log_prior_prop += thread_log_normal_pdf(raw_data[d], mu_proposal, sigma_proposal);
                
                double log_prior_curr = thread_log_normal_pdf(mu_current, 0.0, 10.0) + thread_log_invgamma_pdf(sigma_current, 0.01, 1.0 / 0.01);
                for (int d = 0; d < data_len; ++d) log_prior_curr += thread_log_normal_pdf(raw_data[d], mu_current, sigma_current);
                
                if (std::log(cpu_uniform(cpu_mt)) < (log_prior_prop - log_prior_curr)) { mu_current = mu_proposal; sigma_current = sigma_proposal; }
                extracted_mu[chain_offset + t] = mu_current; extracted_sigma[chain_offset + t] = sigma_current;
            }
        }
    }
};

// [[Rcpp::export]]
Rcpp::List run_mh_rcpp_parallel(int total_samples, int num_chains, Rcpp::NumericVector raw_data, double mu_init, double sigma_init, int seed_base) {
    int samples_per_chain = total_samples / num_chains;
    Rcpp::NumericVector extracted_mu(num_chains * samples_per_chain); Rcpp::NumericVector extracted_sigma(num_chains * samples_per_chain);
    ParallelMCMCSampler worker(samples_per_chain, raw_data.size(), raw_data, mu_init, sigma_init, seed_base, extracted_mu, extracted_sigma);
    RcppParallel::parallelFor(0, num_chains, worker);
    return Rcpp::List::create(Rcpp::_["mu"] = extracted_mu, Rcpp::_["sigma"] = extracted_sigma);
}
')


## ----create_mcmc_sources, echo=FALSE------------------------------------------
mcmc_kernel_src <- '// -*- c -*-
__kernel void mh_sampler_kernel(__global real* out_mu,
                                __global real* out_sigma,
                                __global const real* data,
                                const int data_len,
                                const int samples_per_chain,
                                const int n_chains,
                                const real mu_init,
                                const real sigma_init,
                                const real prop_sd_mu,
                                const real prop_sd_sigma,
                                const int seed) {

  int gid = get_global_id(0);
  int offset = gid * samples_per_chain;
  int max_allowed_index = n_chains * samples_per_chain;

  INIT_MT(seed);

  real mu_current = mu_init;
  real sigma_current = sigma_init;

  if (offset < max_allowed_index) {
    out_mu[offset] = mu_current;
    out_sigma[offset] = sigma_current;
  }

  for (int t = 1; t < samples_per_chain; ++t) {
    int current_idx = offset + t;

    if (current_idx >= max_allowed_index) {
      break;
    }

    real mu_proposal    = rnorm(mu_current, prop_sd_mu);
    real sigma_proposal = rnorm(sigma_current, prop_sd_sigma);

    if (sigma_proposal <= (real)0.01f) {
      out_mu[current_idx] = mu_current;
      out_sigma[current_idx] = sigma_current;
      continue;
    }

    real log_prior_prop = log(dnorm(mu_proposal, (real)0.0f, (real)10.0f)) +
      log(dgamma((real)1.0f/sigma_proposal, (real)0.01f, (real)1.0f/(real)0.01f)) -
      2.0 * log(sigma_proposal);
    real log_lik_prop = (real)0.0f;
    for(int d = 0; d < data_len; ++d) {
      log_lik_prop += log(dnorm(data[d], mu_proposal, sigma_proposal));
    }
    real log_post_prop = log_prior_prop + log_lik_prop;

    real log_prior_curr = log(dnorm(mu_current, (real)0.0f, (real)10.0f)) +
      log(dgamma((real)1.0/sigma_current, (real)0.01f, (real)100.0f)) -
      (real)2.0f * log(sigma_current);

    real log_lik_curr = (real)0.0f;
    for(int d = 0; d < data_len; ++d) {
      log_lik_curr += log(dnorm(data[d], mu_current, sigma_current));
    }
    real log_post_curr = log_prior_curr + log_lik_curr;

    real p_accept = min((real)1.0f, exp(log_post_prop - log_post_curr));

    if (runif(0,1) < p_accept) {
      mu_current = mu_proposal;
      sigma_current = sigma_proposal;
    }

    out_mu[current_idx] = mu_current;
    out_sigma[current_idx] = sigma_current;
  }
}'
writeLines(mcmc_kernel_src, "./mh_sampler.cl")


## ----kernel interface---------------------------------------------------------
mcmc_interface_src <- '// Rcpp function body
int total_samples = as<int>(n_samples);
int chains        = as<int>(n_chains);
int samples_per_chain = total_samples / chains;

NumericVector r_data(data_vector);
int data_len = r_data.size();
int total_output_size = chains * samples_per_chain;

NumericVector out_mu(total_output_size);
NumericVector out_sigma(total_output_size);

Environment e = Environment::global_env();
std::vector<int> r_seed = e[".Random.seed"];
int base_seed = r_seed[r_seed[1] + 1];

Memory<real> GpuData(*device, data_len);
Memory<real> GpuMu(*device, total_output_size);
Memory<real> GpuSigma(*device, total_output_size);

for(int i = 0; i < data_len; ++i) GpuData[i] = (real)r_data[i];

GpuData.write_to_device();

real mu_init_typed       = as<real>(mu_init);
real sigma_init_typed    = as<real>(sigma_init);
real prop_sd_mu_typed    = (real)0.05f;
real prop_sd_sigma_typed = (real)0.05f;

Kernel mh_kernel(*device, chains, "mh_sampler_kernel", 
                 GpuMu, GpuSigma, GpuData, data_len, samples_per_chain, chains,
                 mu_init_typed, sigma_init_typed, prop_sd_mu_typed, prop_sd_sigma_typed, base_seed);

mh_kernel.run();

GpuMu.read_from_device();
GpuSigma.read_from_device();

for(int i = 0; i < total_output_size; ++i) {
    out_mu[i]    = GpuMu[i];
    out_sigma[i] = GpuSigma[i];
}

Function f("runif"); f(1);

return List::create(
    _["mu"]    = out_mu,
    _["sigma"] = out_sigma
);'
writeLines(mcmc_interface_src, "./mh_sampler.cpp")


## ----engine_opencl------------------------------------------------------------
if (getRversion() >= "2.15.1") {
  utils::globalVariables(".parallel_mh_sampler_internal")
}
parallel_MH_sampler <- (function() {
    .parallel_mh_sampler_internal <- NULL
    function(n_samples, n_chains, data_vector, mu_init, sigma_init) {
        if (is.null(.parallel_mh_sampler_internal)) {
            .parallel_mh_sampler_internal <<- oclFunction(
                signature = methods::signature(
                                         n_samples   = "integer",
                                         n_chains    = "integer",
                                         data_vector = "numeric",
                                         mu_init     = "numeric",
                                         sigma_init  = "numeric"
                                     ),
                kernel_file     = "./mh_sampler.cl",
                interface_file  = "./mh_sampler.cpp"
            )
        }
        return(.parallel_mh_sampler_internal(n_samples, n_chains, data_vector, mu_init, sigma_init))
    }
})()


## ----engine_opencl_float------------------------------------------------------
if (getRversion() >= "2.15.1") {
  utils::globalVariables(".parallel_mh_sampler_float_internal")
}
parallel_MH_sampler_float <- (function() {
    .parallel_mh_sampler_float_internal <- NULL
    function(n_samples, n_chains, data_vector, mu_init, sigma_init) {
        if (is.null(.parallel_mh_sampler_float_internal)) {
            .parallel_mh_sampler_float_internal <<- oclFunction(
                signature = methods::signature(
                                         n_samples   = "integer",
                                         n_chains    = "integer",
                                         data_vector = "numeric",
                                         mu_init     = "numeric",
                                         sigma_init  = "numeric"
                                     ),
                kernel_file     = "./mh_sampler.cl",
                interface_file  = "./mh_sampler.cpp",
                force_float     = TRUE
            )
        }
        return(.parallel_mh_sampler_float_internal(n_samples, n_chains, data_vector, mu_init, sigma_init))
    }
})()


## ----warm_up------------------------------------------------------------------
# --- COLDSTART ELIMINATION / WARM-UP ---
invisible(run_mh_pure_r(2L, 10L, raw_data, mu_empirical, sigma_empirical, seed_base))
invisible(run_mh_r_subprocesses(2L, 10L, raw_data, mu_empirical, sigma_empirical, seed_base))
invisible(run_mh_rcpp_parallel(20L, 10L, raw_data, mu_empirical, sigma_empirical, seed_base))
ActivateDevice(0)
invisible(parallel_MH_sampler(as.integer(100), as.integer(100), raw_data, mu_empirical, sigma_empirical))
invisible(parallel_MH_sampler_float(as.integer(100), as.integer(100), raw_data, mu_empirical, sigma_empirical))
ActivateDevice(1)
invisible(parallel_MH_sampler(as.integer(100), as.integer(100), raw_data, mu_empirical, sigma_empirical))
ActivateDevice(2)
invisible(parallel_MH_sampler(as.integer(100), as.integer(100), raw_data, mu_empirical, sigma_empirical))
invisible(parallel_MH_sampler_float(as.integer(100), as.integer(100), raw_data, mu_empirical, sigma_empirical))


## ----pure_R-------------------------------------------------------------------
timer_start <- Sys.time()
output_r    <- run_mh_pure_r(samples_per_chain, num_chains, raw_data, mu_empirical, sigma_empirical, seed_base)
time_pure_r <- as.numeric(difftime(Sys.time(), timer_start, units = "secs"))


## ----r_mclapply---------------------------------------------------------------
timer_start <- Sys.time()
output_mcl  <- run_mh_r_subprocesses(samples_per_chain, num_chains, raw_data, mu_empirical, sigma_empirical, seed_base)
time_mcl    <- as.numeric(difftime(Sys.time(), timer_start, units = "secs"))


## ----rcpp_serial--------------------------------------------------------------
timer_start <- Sys.time()
output_spp  <- run_mh_rcpp_serial(total_samples, num_chains, raw_data, mu_empirical, sigma_empirical, seed_base)
time_serial <- as.numeric(difftime(Sys.time(), timer_start, units = "secs"))


## ----rcpp_parallel------------------------------------------------------------
timer_start <- Sys.time()
output_tbb  <- run_mh_rcpp_parallel(total_samples, num_chains, raw_data, mu_empirical, sigma_empirical, seed_base)
time_tbb    <- as.numeric(difftime(Sys.time(), timer_start, units = "secs"))


## ----device 0-----------------------------------------------------------------
ActivateDevice(0)
GetActiveDeviceInfo()


## ----openclear nvidia---------------------------------------------------------
timer_start <- Sys.time()
output_gpu  <- parallel_MH_sampler(as.integer(total_samples), as.integer(num_chains), raw_data, mu_empirical, sigma_empirical)
time_gpu    <- as.numeric(difftime(Sys.time(), timer_start, units = "secs"))


## ----openclear nvidia float---------------------------------------------------
timer_start <- Sys.time()
output_gpu_float  <- parallel_MH_sampler_float(as.integer(total_samples), as.integer(num_chains), raw_data, mu_empirical, sigma_empirical)
time_gpu_float    <- as.numeric(difftime(Sys.time(), timer_start, units = "secs"))


## ----device 1-----------------------------------------------------------------
ActivateDevice(1)
GetActiveDeviceInfo()


## ----openclear intel Xe-------------------------------------------------------
timer_start <- Sys.time()
output_intel_gpu  <- parallel_MH_sampler(as.integer(total_samples), as.integer(num_chains), raw_data, mu_empirical, sigma_empirical)
time_intel_gpu    <- as.numeric(difftime(Sys.time(), timer_start, units = "secs"))


## ----device 2-----------------------------------------------------------------
ActivateDevice(2)
GetActiveDeviceInfo()


## ----openclear Intel CPU------------------------------------------------------
timer_start <- Sys.time()
output_cpu  <- parallel_MH_sampler(as.integer(total_samples), as.integer(num_chains), raw_data, mu_empirical, sigma_empirical)
time_cpu    <- as.numeric(difftime(Sys.time(), timer_start, units = "secs"))


## ----openclear Intel CPU float------------------------------------------------
timer_start <- Sys.time()
output_cpu_float  <- parallel_MH_sampler_float(as.integer(total_samples), as.integer(num_chains), raw_data, mu_empirical, sigma_empirical)
time_cpu_float    <- as.numeric(difftime(Sys.time(), timer_start, units = "secs"))


## ----print_table, echo=FALSE--------------------------------------------------
# Helper function to extract mean estimates safely
get_mu_hat    <- function(obj) { round(mean(obj$mu), 4) }
get_sigma_hat <- function(obj) { round(mean(obj$sigma), 4) }

performance_matrix <- data.frame(
  Engine = c(
    "🔴 Pure R Script (1 Core)", 
    "🟤 R Subprocesses (mclapply Multi)", 
    "🟠 Native C++ Kernel (1 Thread)", 
    "🟡 RcppParallel TBB (CPU Threads)", 
    "🚀 OpenCLeaR: NVIDIA GPU (Dev 0) double",
    "🚀 OpenCLeaR: NVIDIA GPU (Dev 0) float",
    "🚀 OpenCLeaR: Intel GPU (Dev 1) float",
    "🚀 OpenCLeaR: Intel CPU (Dev 2) POCL double",
    "🚀 OpenCLeaR: Intel CPU (Dev 2) POCL float"
  ),
  Precision = c("Double", "Double", "Double", "Double", "Double", "Float", "Float", "Double", "Float"),
  Runtime = c(
    sprintf("%.4fs", time_pure_r), 
    sprintf("%.4fs", time_mcl), 
    sprintf("%.4fs", time_serial), 
    sprintf("%.4fs", time_tbb), 
    sprintf("%.4fs", time_gpu),
    sprintf("%.4fs", time_gpu_float),
    sprintf("%.4fs", time_intel_gpu),
    sprintf("%.4fs", time_cpu),
    sprintf("%.4fs", time_cpu_float)
  ),
  Speedup = c(
    "1.00x (Baseline)", 
    sprintf("%.2fx", time_pure_r / time_mcl), 
    sprintf("%.2fx", time_pure_r / time_serial), 
    sprintf("%.2fx", time_pure_r / time_tbb), 
    sprintf("%.2fx", time_pure_r / time_gpu),
    sprintf("%.2fx", time_pure_r / time_gpu_float),
    sprintf("%.2fx", time_pure_r / time_intel_gpu),
    sprintf("%.2fx", time_pure_r / time_cpu),
    sprintf("%.2fx", time_pure_r / time_cpu_float)
  ),
  Mu_Hat = c(
    get_mu_hat(output_r),
    get_mu_hat(output_mcl),
    get_mu_hat(output_spp),
    get_mu_hat(output_tbb),
    get_mu_hat(output_gpu),
    get_mu_hat(output_gpu_float),
    get_mu_hat(output_intel_gpu),
    get_mu_hat(output_cpu),
    get_mu_hat(output_cpu_float)
  ),
  Sigma_Hat = c(
    get_sigma_hat(output_r),
    get_sigma_hat(output_mcl),
    get_sigma_hat(output_spp),
    get_sigma_hat(output_tbb),
    get_sigma_hat(output_gpu),
    get_sigma_hat(output_gpu_float),
    get_sigma_hat(output_intel_gpu),
    get_sigma_hat(output_cpu),
    get_sigma_hat(output_cpu_float)
  ),
  check.names = FALSE
)

knitr::kable(performance_matrix, 
             caption = sprintf("Execution Metrics and Parameter Validation on XPS 17 (True Mu = %.2f, True Sigma = %.2f)", mu_empirical, sigma_empirical))


## ----plotting_density, fig.width=10, fig.height=4-----------------------------
# We use the double-precision NVIDIA output for validation
visualization_df <- data.frame(
  mu    = output_gpu$mu,
  sigma = output_gpu$sigma
)

# Density map for Mu (µ)
plot_mu <- ggplot(visualization_df, aes(x = mu)) +
  geom_density(fill = "#2ca02c", alpha = 0.4, color = "#1a601a") +
  geom_vline(xintercept = mu_empirical, linetype = "dashed", color = "red", linewidth = 1) +
  labs(title = "Posterior Density for Mu (µ)", 
       subtitle = "Dashed Red Line = Empirical Mean Base", 
       x = "Parameter Value", y = "Density Space") +
  theme_minimal()

# Density map for Sigma (σ)
plot_sigma <- ggplot(visualization_df, aes(x = sigma)) +
  geom_density(fill = "#1f77b4", alpha = 0.4, color = "#11456b") +
  geom_vline(xintercept = sigma_empirical, linetype = "dashed", color = "red", linewidth = 1) +
  labs(title = "Posterior Density for Sigma (σ)", 
       subtitle = "Dashed Red Line = Empirical SD Base", 
       x = "Parameter Value", y = "Density Space") +
  theme_minimal()

grid.arrange(plot_mu, plot_sigma, ncol = 2)


## ----traceplot, fig.width=10, fig.height=5------------------------------------
index_steps <- 1:samples_per_chain

traceplot_df <- data.frame(
  Iteration = rep(index_steps, 3),
  Chain     = rep(c("Chain 1", "Chain 2", "Chain 3"), each = samples_per_chain),
  Mu_Value  = c(output_gpu$mu[1:samples_per_chain], 
                output_gpu$mu[(samples_per_chain + 1):(2 * samples_per_chain)], 
                output_gpu$mu[(2 * samples_per_chain + 1):(3 * samples_per_chain)])
)

ggplot(traceplot_df, aes(x = Iteration, y = Mu_Value, color = Chain)) +
  geom_line(alpha = 0.6) +
  scale_color_manual(values = c("#d62728", "#ff7f0e", "#1f77b4")) +
  labs(title = "MCMC Parameter Traceplot for Mu (µ)",
       subtitle = "Independent path histories of the first 3 OpenCL parallelized chains",
       x = "Iteration Window within Chain", y = "Sampled Parameter State") +
  theme_minimal() +
  theme(legend.position = "bottom")


## ----binary_cleanup-----------------------------------------------------------
CleanCLCache()

