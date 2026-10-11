library(Rcpp)



# ==============================================================================
# 🏎️ B. DER MULTI-THREADING CPU SAMPLER (Nativer C++11 std::mt19937, Intel TBB)
# ==============================================================================
cat("⏳ Kompiliere parallelisiertes TBB-Vergleichsobjekt via RcppParallel...\n")

Rcpp::sourceCpp(code = '
// [[Rcpp::depends(RcppParallel)]]
#include <RcppParallel.h>
#include <Rcpp.h>
#include <cmath>
#include <random> // 🚀 Für std::mt19937 und Verteilungen!

struct ParallelMCMCSampler : public RcppParallel::Worker {
    int samples_per_chain;
    int data_len;
    RcppParallel::RVector<double> data_vector;
    double mu_init;
    double sigma_init;
    int base_seed;

    RcppParallel::RVector<double> out_mu;
    RcppParallel::RVector<double> out_sigma;

    ParallelMCMCSampler(int samples_per_chain, int data_len, Rcpp::NumericVector data_vector,
                        double mu_init, double sigma_init, int base_seed,
                        Rcpp::NumericVector out_mu, Rcpp::NumericVector out_sigma)
        : samples_per_chain(samples_per_chain), data_len(data_len), data_vector(data_vector),
          mu_init(mu_init), sigma_init(sigma_init), base_seed(base_seed),
          out_mu(out_mu), out_sigma(out_sigma) {}

    // Thread-sichere mathematische Dichten auf Log-Skala
    inline double thread_log_normal_pdf(double x, double mean, double sd) const {
        return -0.5 * std::log(2.0 * M_PI) - std::log(sd) - 0.5 * std::pow((x - mean) / sd, 2.0);
    }
    inline double thread_log_invgamma_pdf(double x, double alpha, double beta) const {
        return alpha * std::log(beta) - std::lgamma(alpha) - (alpha + 1.0) * std::log(x) - (beta / x);
    }

    void operator()(std::size_t begin_chain, std::size_t end_chain) {
        for (std::size_t c = begin_chain; c < end_chain; ++c) {
            int offset = c * samples_per_chain;
            
            // 🚀 MODERN C++ RNG: Jede Kette kriegt ihren eigenen, isolierten Mersenne-Twister!
            std::mt19937 cpu_mt(base_seed + (c * 777));
            std::normal_distribution<double> cpu_normal(0.0, 0.05); // Proposal SD 0.05
            std::uniform_real_distribution<double> cpu_uniform(0.0, 1.0);

            double mu_current = mu_init;
            double sigma_current = sigma_init;
            
            out_mu[offset] = mu_current;
            out_sigma[offset] = sigma_current;
            
            for (int t = 1; t < samples_per_chain; ++t) {
                // Vorschläge thread-sicher direkt aus der std-Hardware-Pipeline ziehen!
                double mu_proposal    = mu_current + cpu_normal(cpu_mt);
                double sigma_proposal = sigma_current + cpu_normal(cpu_mt);
                
                if (sigma_proposal <= 0.01) {
                    out_mu[offset + t] = mu_current;
                    out_sigma[offset + t] = sigma_current;
                    continue;
                }
                
                double log_prior_prop = thread_log_normal_pdf(mu_proposal, 0.0, 10.0) + thread_log_invgamma_pdf(sigma_proposal, 0.01, 1.0 / 0.01);
                double log_lik_prop = 0.0;
                for (int d = 0; d < data_len; ++d) {
                    log_lik_prop += thread_log_normal_pdf(data_vector[d], mu_proposal, sigma_proposal);
                }
                double log_post_prop = log_prior_prop + log_lik_prop;
                
                double log_prior_curr = thread_log_normal_pdf(mu_current, 0.0, 10.0) + thread_log_invgamma_pdf(sigma_current, 0.01, 1.0 / 0.01);
                double log_lik_curr = 0.0;
                for (int d = 0; d < data_len; ++d) {
                    log_lik_curr += thread_log_normal_pdf(data_vector[d], mu_current, sigma_current);
                }
                double log_post_curr = log_prior_curr + log_lik_curr;
                
                if (std::log(cpu_uniform(cpu_mt)) < (log_post_prop - log_post_curr)) {
                    mu_current = mu_proposal;
                    sigma_current = sigma_proposal;
                }
                
                out_mu[offset + t] = mu_current;
                out_sigma[offset + t] = sigma_current;
            }
        }
    }
};

// [[Rcpp::export]]
Rcpp::List run_mh_rcpp_parallel(int n_samples, int n_chains, Rcpp::NumericVector data_vector, 
                               double mu_init, double sigma_init) {
    
    int samples_per_chain = n_samples / n_chains;
    int data_len = data_vector.size();
    int total_output_size = n_chains * samples_per_chain;
    
    Rcpp::NumericVector out_mu(total_output_size);
    Rcpp::NumericVector out_sigma(total_output_size);
    
    Rcpp::Environment e = Rcpp::Environment::global_env();
    Rcpp::IntegerVector r_seed = e[".Random.seed"];
    
    int random_idx = r_seed[0];
    int base_seed  = r_seed[random_idx + 1];
    
    ParallelMCMCSampler worker(samples_per_chain, data_len, data_vector, mu_init, sigma_init, 
                               base_seed, out_mu, out_sigma);
    
    RcppParallel::parallelFor(0, n_chains, worker);
    
    Rcpp::Function f("runif"); f(1);
    return Rcpp::List::create(Rcpp::_["mu"] = out_mu, Rcpp::_["sigma"] = out_sigma);
}
')
cat("🎉 RcppParallel-Inline-Objekt 'run_mh_rcpp_parallel' einsatzbereit!\n")
