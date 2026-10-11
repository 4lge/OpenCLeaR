library(Rcpp)

cat("⏳ Kompiliere serielles CPU-Vergleichsobjekt via Rcpp::sourceCpp()...\n")

Rcpp::sourceCpp(code = '
#include <Rcpp.h>
#include <cmath>

// [[Rcpp::plugins(cpp17)]]

// [[Rcpp::export]]
Rcpp::List run_mh_rcpp_serial(int n_samples, int n_chains, Rcpp::NumericVector data_vector, 
                             double mu_init, double sigma_init) {
    
    int samples_per_chain = n_samples / n_chains;
    int data_len = data_vector.size();
    int total_output_size = n_chains * samples_per_chain;

    Rcpp::NumericVector out_mu(total_output_size);
    Rcpp::NumericVector out_sigma(total_output_size);

    Rcpp::Environment e = Rcpp::Environment::global_env();
    Rcpp::IntegerVector r_seed = e[".Random.seed"];
    
    // 🛡️ BITSCHARFE INTEGRAL-EXTRAKTION (Verhindert die Rcpp-Sugar-Falle!)
    int random_idx = r_seed[1];
    int base_seed  = r_seed[random_idx + 1];

    for (int c = 0; c < n_chains; ++c) {
        int offset = c * samples_per_chain;
        
        // Synchroner, thread-lokaler Xorshift für identischen RNG-Takt
        unsigned int seed = base_seed + (c * 777);
        auto inline_rand_01 = [&seed]() -> double {
            seed ^= seed << 13; seed ^= seed >> 17; seed ^= seed << 5;
            return (double)seed / (double)4294967295.0;
        };
        auto inline_rnorm = [&inline_rand_01](double mean, double sd) -> double {
            double u1 = inline_rand_01(); double u2 = inline_rand_01();
            while(u1 <= 1e-15) u1 = inline_rand_01();
            return mean + sd * std::sqrt(-2.0 * std::log(u1)) * std::cos(2.0 * M_PI * u2);
        };

        double mu_current = mu_init;
        double sigma_current = sigma_init;
        
        out_mu[offset] = mu_current;
        out_sigma[offset] = sigma_current;
        
        for (int t = 1; t < samples_per_chain; ++t) {
            double mu_proposal    = inline_rnorm(mu_current, 0.05);
            double sigma_proposal = inline_rnorm(sigma_current, 0.05);
            
            if (sigma_proposal <= 0.01) {
                out_mu[offset + t] = mu_current;
                out_sigma[offset + t] = sigma_current;
                continue;
            }
            
            // Nutzt die hochoptimierten, numerisch stabilen R-Standard-Routinen
            double log_prior_prop = R::dnorm(mu_proposal, 0.0, 10.0, true) + 
                                    R::dgamma(1.0 / sigma_proposal, 0.01, 1.0 / 0.01, true);
            double log_lik_prop = 0.0;
            for (int d = 0; d < data_len; ++d) {
                log_lik_prop += R::dnorm(data_vector[d], mu_proposal, sigma_proposal, true);
            }
            double log_post_prop = log_prior_prop + log_lik_prop;
            
            double log_prior_curr = R::dnorm(mu_current, 0.0, 10.0, true) + 
                                    R::dgamma(1.0 / sigma_current, 0.01, 1.0 / 0.01, true);
            double log_lik_curr = 0.0;
            for (int d = 0; d < data_len; ++d) {
                log_lik_curr += R::dnorm(data_vector[d], mu_current, sigma_current, true);
            }
            double log_post_curr = log_prior_curr + log_lik_curr;
            
            if (std::log(inline_rand_01()) < (log_post_prop - log_post_curr)) {
                mu_current = mu_proposal;
                sigma_current = sigma_proposal;
            }
            
            out_mu[offset + t] = mu_current;
            out_sigma[offset + t] = sigma_current;
        }
    }
    
    Rcpp::Function f("runif"); f(1);
    return Rcpp::List::create(Rcpp::_["mu"] = out_mu, Rcpp::_["sigma"] = out_sigma);
}
')
cat("🎉 Rcpp-Inline-Objekt 'run_mh_rcpp_serial' fehlerfrei kompiliert!\n")
