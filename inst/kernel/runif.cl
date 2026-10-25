// -*- mode: C -*-
    
kernel void unif_rng(global real* output, const int seed,
                     const real lower, const real upper) {
  
  // Initialize Mersenne Twister state
  INIT_MT(seed);
  
  real r_unif = runif(lower, upper);
  
  output[get_global_id(0)] = r_unif;
}
