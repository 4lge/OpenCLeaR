run_mh_pure_r <- function(n_samples, n_chains, data_vector, mu_init, sigma_init) {
  samples_per_chain <- as.integer(n_samples / n_chains)
  data_len <- length(data_vector)
  total_output_size <- n_chains * samples_per_chain
  
  out_mu <- numeric(total_output_size)
  out_sigma <- numeric(total_output_size)
  
  # Base Seed exakt wie im C++ Interface extrahieren
  r_seed <- get(".Random.seed", envir = .GlobalEnv)
  base_seed <- r_seed[r_seed[1] + 1] 
  
  for (c in 1:n_chains) {
    offset <- (c - 1) * samples_per_chain
    set.seed(base_seed + ((c - 1) * 777)) # Synchroner Seed-Takt!
    
    mu_current <- mu_init
    sigma_current <- sigma_init
    
    out_mu[offset + 1] <- mu_current
    out_sigma[offset + 1] <- sigma_current
    
    for (t in 2:samples_per_chain) {
      # Proposals generieren mit Standard-R-Schrittweite 0.05
      mu_proposal <- rnorm(1, mean = mu_current, sd = 0.05)
      sigma_proposal <- rnorm(1, mean = sigma_current, sd = 0.05)
      
      if (sigma_proposal <= 0.01) {
        out_mu[offset + t] <- mu_current
        out_sigma[offset + t] <- sigma_current
        next
      }
      
      # 🎯 Nutzt ehrliche Standard R-Verteilungs-Funktionen auf Log-Skala!
      log_prior_prop <- dnorm(mu_proposal, 0.0, 10.0, log = TRUE) + 
                        dgamma(1 / sigma_proposal, shape = 0.01, scale = 1 / 0.01, log = TRUE)
      log_lik_prop <- sum(dnorm(data_vector, mu_proposal, sigma_proposal, log = TRUE))
      log_post_prop <- log_prior_prop + log_lik_prop
      
      log_prior_curr <- dnorm(mu_current, 0.0, 10.0, log = TRUE) + 
                        dgamma(1 / sigma_current, shape = 0.01, scale = 1 / 0.01, log = TRUE)
      log_lik_curr <- sum(dnorm(data_vector, mu_current, sigma_current, log = TRUE))
      log_post_curr <- log_prior_curr + log_lik_curr
      
      if (log(runif(1)) < (log_post_prop - log_post_curr)) {
        mu_current <- mu_proposal
        sigma_current <- sigma_proposal
      }
      
      out_mu[offset + t] <- mu_current
      out_sigma[offset + t] <- sigma_current
    }
  }
  return(list(mu = out_mu, sigma = out_sigma))
}
