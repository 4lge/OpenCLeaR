# ==============================================================================
# 🔴 1. DER REINE SERIELLE R-CODE (Die Abschreckung)
# ==============================================================================
run_mh_pure_r <- function(samples_per_chain, n_chains, data_vector, mu_init, sigma_init, base_seed) {
  total_size <- n_chains * samples_per_chain
  out_mu <- numeric(total_size)
  out_sigma <- numeric(total_size)
  
  for (c in 1:n_chains) {
    offset <- (c - 1) * samples_per_chain
    set.seed(base_seed + ((c - 1) * 777))
    
    mu_current <- mu_init
    sigma_current <- sigma_init
    out_mu[offset + 1] <- mu_current
    out_sigma[offset + 1] <- sigma_current
    
    for (t in 2:samples_per_chain) {
      mu_proposal <- rnorm(1, mean = mu_current, sd = 0.05)
      sigma_proposal <- rnorm(1, mean = sigma_current, sd = 0.05)
      
      if (sigma_proposal <= 0.01) {
        out_mu[offset + t] <- mu_current
        out_sigma[offset + t] <- sigma_current
        next
      }
      
      log_prior_prop <- dnorm(mu_proposal, 0.0, 10.0, log = TRUE) + 
                        dgamma(1 / sigma_proposal, shape = 0.01, scale = 1 / 0.01, log = TRUE)
      log_lik_prop <- sum(dnorm(data_vector, mu_proposal, sigma_proposal, log = TRUE))
      
      log_prior_curr <- dnorm(mu_current, 0.0, 10.0, log = TRUE) + 
                        dgamma(1 / sigma_current, shape = 0.01, scale = 1 / 0.01, log = TRUE)
      log_lik_curr <- sum(dnorm(data_vector, mu_current, sigma_current, log = TRUE))
      
      if (log(runif(1)) < ((log_prior_prop + log_lik_prop) - (log_prior_curr + log_lik_curr))) {
        mu_current <- mu_proposal
        sigma_current = sigma_proposal
      }
      out_mu[offset + t] <- mu_current
      out_sigma[offset + t] <- sigma_current
    }
  }
  return(list(mu = out_mu, sigma = out_sigma))
}

# ==============================================================================
# 🟤 2. DAS R-SUBPROZESS-PARALLELISIERUNGSDING (parallel::mclapply)
# ==============================================================================
run_mh_r_subprocesses <- function(samples_per_chain, n_chains, data_vector, mu_init, sigma_init, base_seed) {
  cores_to_use <- parallel::detectCores()
  
  chain_results <- parallel::mclapply(1:n_chains, function(c) {
    set.seed(base_seed + ((c - 1) * 777))
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
      
      lp_prop <- dnorm(mu_prop, 0.0, 10.0, log = TRUE) + 
                 dgamma(1 / sigma_prop, shape = 0.01, scale = 1 / 0.01, log = TRUE) + 
                 sum(dnorm(data_vector, mu_prop, sigma_prop, log = TRUE))
                 
      lp_curr <- dnorm(mu_curr, 0.0, 10.0, log = TRUE) + 
                 dgamma(1 / sigma_curr, shape = 0.01, scale = 1 / 0.01, log = TRUE) + 
                 sum(dnorm(data_vector, mu_curr, sigma_curr, log = TRUE))
                 
      if (log(runif(1)) < (lp_prop - lp_curr)) { 
        mu_curr <- mu_prop
        sigma_curr <- sigma_prop 
      }
      m_mu[t] <- mu_curr
      m_sigma[t] <- sigma_curr
    }
    return(list(mu = m_mu, sigma = m_sigma))
  }, mc.cores = cores_to_use)
  
  out_mu <- unlist(lapply(chain_results, function(x) x$mu))
  out_sigma <- unlist(lapply(chain_results, function(x) x$sigma))
  return(list(mu = out_mu, sigma = out_sigma))
}
