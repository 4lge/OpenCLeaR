// -*- c -*-
__kernel void mh_recurrent_sampler_kernel(__global real* out_mu,
                                          __global real* out_sigma,
                                          __global const real* data,
                                          const int data_len,
                                          const int window_width,
                                          const int total_mcmc_steps,
                                          const int n_chains,
                                          const real mu_init,
                                          const real sigma_init,
                                          const real prop_sd_mu,
                                          const real prop_sd_sigma,
                                          const int seed) {

  int gid = get_global_id(0);
  int offset = gid * window_width;
  int max_allowed_index = n_chains * window_width;

  // 🔐 1. initialize Mersenne Twister state as array
  INIT_MT(seed);
 
  real mu_current = mu_init;
  real sigma_current = sigma_init;

  if (offset < max_allowed_index) {
    out_mu[offset] = mu_current;
    out_sigma[offset] = sigma_current;
  }

  // 🔄 serial MCMC-loop whithin parallel OpenCL thread.
  // loop for total_mcmc_steps, but write modulo window_width.
  // this makes several recurrent loops through the window,
  // only the last recurrence is returned back.
  for (int t = 1; t < total_mcmc_steps; ++t) {

    // use libkernel function for rnorm in analogy to base R functions
    real mu_proposal    = rnorm(mu_current, prop_sd_mu);
    real sigma_proposal = rnorm(sigma_current, prop_sd_sigma);

    // ring buffer index modulo window_width
    int write_pos = offset + (t % window_width);

    // avoid lockups on GPUs with shared memory.
    if (write_pos >= max_allowed_index) {
      break;
    }

    if (sigma_proposal <= (real)0.01) {
      out_mu[write_pos] = mu_current;
      out_sigma[write_pos] = sigma_current;
      continue;
    }

    // --- 1. log-posterior of proposal
    real log_prior_prop = log(dnorm(mu_proposal, (real)0.0, (real)10.0)) +
      log(dgamma((real)1.0/sigma_proposal, (real)0.01, (real)1.0/(real)0.01)) -
      2.0 * log(sigma_proposal);
    real log_lik_prop = (real)0.0;
    for(int d = 0; d < data_len; ++d) {
      log_lik_prop += log(dnorm(data[d], mu_proposal, sigma_proposal));
    }
    real log_post_prop = log_prior_prop + log_lik_prop;

    // --- 2. log-posterior for current state
    real log_prior_curr = log(dnorm(mu_current, (real)0.0, (real)10.0)) +
      log(dgamma((real)1.0/sigma_current, (real)0.01, (real)100.0)) -
      2.0 * log(sigma_current);

    real log_lik_curr = (real)0.0;
    for(int d = 0; d < data_len; ++d) {
      log_lik_curr += log(dnorm(data[d], mu_current, sigma_current));
    }
    real log_post_curr = log_prior_curr + log_lik_curr;

    // --- 3. acceptance?
    real p_accept = min((real)1.0, exp(log_post_prop - log_post_curr));

    if (runif(0,1) < p_accept) {
      mu_current = mu_proposal;
      sigma_current = sigma_proposal;
    }

    // 🎯 ring buffer write access:
    out_mu[write_pos] = mu_current;
    out_sigma[write_pos] = sigma_current;
  }
}
