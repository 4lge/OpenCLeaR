// -*- mode: C -*-

kernel void mvnorm_cdf_mc(global real* output, const int seed,
                          global const real* lower, global const real* upper,
                          global const real* mu, global real* Sigma_L,
                          const int dim, const int n_per_thread) {
  int gid = get_global_id(0);
  
  // Initialize Mersenne Twister state
  INIT_MT(seed);
  
  real ws[64]; // Array for column accumulation
  output[gid] = pmvnorm(lower, upper, mu, Sigma_L, dim, n_per_thread, ws);
}
