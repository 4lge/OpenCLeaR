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
