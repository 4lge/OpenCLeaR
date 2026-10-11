library(Rcpp)
library(RcppParallel)

cat("⏳ Kompiliere Rcpp und RcppParallel Triebwerke via sourceCpp...\n")

Rcpp::sourceCpp(code = '
#include <RcppParallel.h>
#include <Rcpp.h>
#include <cmath>
#include <random>

// [[Rcpp::plugins(cpp17)]]
// [[Rcpp::depends(RcppParallel)]]

// 🧡 UNZERSTÖRBARER SERIELLER CPU-KERN
// [[Rcpp::export]]
Rcpp::List run_mh_rcpp_serial(int n_samples, int n_chains, Rcpp::NumericVector data_vector, double mu_init, double sigma_init, int base_seed) {
    int samples_per_chain = n_samples / n_chains;
    int data_len = data_vector.size();
    Rcpp::NumericVector out_mu(n_chains * samples_per_chain);
    Rcpp::NumericVector out_sigma(n_chains * samples_per_chain);

    for (int c = 0; c < n_chains; ++c) {
        int offset = c * samples_per_chain;
        std::mt19937 cpu_mt(base_seed + (c * 777));
        std::normal_distribution<double> cpu_normal(0.0, 0.05);
        std::uniform_real_distribution<double> cpu_uniform(0.0, 1.0);
        
        double mu_current = mu_init; 
        double sigma_current = sigma_init;
        out_mu[offset] = mu_current; 
        out_sigma[offset] = sigma_current;

        for (int t = 1; t < samples_per_chain; ++t) {
            double mu_proposal    = mu_current + cpu_normal(cpu_mt); 
            double sigma_proposal = sigma_current + cpu_normal(cpu_mt);
            
            if (sigma_proposal <= 0.01) { 
                out_mu[offset + t] = mu_current; 
                out_sigma[offset + t] = sigma_current; 
                continue; 
            }
            
            double lp_prop = R::dnorm(mu_proposal, 0.0, 10.0, true) + R::dgamma(1.0 / sigma_proposal, 0.01, 1.0 / 0.01, true);
            for (int d = 0; d < data_len; ++d) lp_prop += R::dnorm(data_vector[d], mu_proposal, sigma_proposal, true);
            
            double lp_curr = R::dnorm(mu_current, 0.0, 10.0, true) + R::dgamma(1.0 / sigma_current, 0.01, 1.0 / 0.01, true);
            for (int d = 0; d < data_len; ++d) lp_curr += R::dnorm(data_vector[d], mu_current, sigma_current, true);
            
            if (std::log(cpu_uniform(cpu_mt)) < (lp_prop - lp_curr)) { 
                mu_current = mu_proposal; 
                sigma_current = sigma_proposal; 
            }
            out_mu[offset + t] = mu_current; 
            out_sigma[offset + t] = sigma_current;
        }
    }
    return Rcpp::List::create(Rcpp::_["mu"] = out_mu, Rcpp::_["sigma"] = out_sigma);
}

// 💛 UNZERSTÖRBARER MULTI-THREADING CPU-KERN (Intel TBB)
struct ParallelMCMCSampler : public RcppParallel::Worker {
    int samples_per_chain; int data_len; RcppParallel::RVector<double> data_vector;
    double mu_init; double sigma_init; int base_seed;
    RcppParallel::RVector<double> out_mu; RcppParallel::RVector<double> out_sigma;
    
    ParallelMCMCSampler(int s, int d, Rcpp::NumericVector dv, double mi, double si, int bs, Rcpp::NumericVector om, Rcpp::NumericVector os)
        : samples_per_chain(s), data_len(d), data_vector(dv), mu_init(mi), sigma_init(si), base_seed(bs), out_mu(om), out_sigma(os) {}

    inline double thread_log_normal_pdf(double x, double m, double s) const { return -0.5 * std::log(2.0 * M_PI) - std::log(s) - 0.5 * std::pow((x - m) / s, 2.0); }
    inline double thread_log_invgamma_pdf(double x, double a, double b) const { return a * std::log(b) - std::lgamma(a) - (a + 1.0) * std::log(x) - (b / x); }

    void operator()(std::size_t begin_chain, std::size_t end_chain) {
        for (std::size_t c = begin_chain; c < end_chain; ++c) {
            int offset = c * samples_per_chain;
            std::mt19937 cpu_mt(base_seed + (c * 777));
            std::normal_distribution<double> cpu_normal(0.0, 0.05);
            std::uniform_real_distribution<double> cpu_uniform(0.0, 1.0);
            
            double mu_current = mu_init; 
            double sigma_current = sigma_init;
            out_mu[offset] = mu_current; 
            out_sigma[offset] = sigma_current;

            for (int t = 1; t < samples_per_chain; ++t) {
                double mu_proposal    = mu_current + cpu_normal(cpu_mt); 
                double sigma_proposal = sigma_current + cpu_normal(cpu_mt);
                
                if (sigma_proposal <= 0.01001) { 
                    out_mu[offset + t] = mu_current; 
                    out_sigma[offset + t] = sigma_current; 
                    continue; 
                }
                
                double lp_prop = thread_log_normal_pdf(mu_proposal, 0.0, 10.0) + thread_log_invgamma_pdf(sigma_proposal, 0.01, 1.0 / 0.01);
                for (int d = 0; d < data_len; ++d) lp_prop += thread_log_normal_pdf(data_vector[d], mu_proposal, sigma_proposal);
                
                double lp_curr = thread_log_normal_pdf(mu_current, 0.0, 10.0) + thread_log_invgamma_pdf(sigma_current, 0.01, 1.0 / 0.01);
                for (int d = 0; d < data_len; ++d) lp_curr += thread_log_normal_pdf(data_vector[d], mu_current, sigma_current);
                
                if (std::log(cpu_uniform(cpu_mt)) < (lp_prop - lp_curr)) { 
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
Rcpp::List run_mh_rcpp_parallel(int n_samples, int n_chains, Rcpp::NumericVector data_vector, double mu_init, double sigma_init, int base_seed) {
    int samples_per_chain = n_samples / n_chains;
    Rcpp::NumericVector out_mu(n_chains * samples_per_chain); 
    Rcpp::NumericVector out_sigma(n_chains * samples_per_chain);
    
    ParallelMCMCSampler worker(samples_per_chain, data_vector.size(), data_vector, mu_init, sigma_init, base_seed, out_mu, out_sigma);
    RcppParallel::parallelFor(0, n_chains, worker);
    return Rcpp::List::create(Rcpp::_["mu"] = out_mu, Rcpp::_["sigma"] = out_sigma);
}
')
cat("🎉 CPU-Inline-Triebwerke fehlerfrei einsatzbereit!\n")
