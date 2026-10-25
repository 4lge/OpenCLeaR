// -*- mode: C -*-
    
kernel void norm_rng(global real* output, const int seed, 
                     const real mu, const real sigma) {
         
  // Initialize Mersenne Twister state
  INIT_MT(seed);
  
  real r_norm = rnorm(mu, sigma);

  output[get_global_id(0)] = r_norm;
}
