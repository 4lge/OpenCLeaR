// -*- mode: C -*-
    
kernel void mvnorm_rng(global real* output, const int seed, 
                       global const real* mu, global real* Sigma_L, 
                       const int dim) {
  
  // Initialize Mersenne Twister state
  INIT_MT(seed);
  
  // Target pointer for exactly this thread (line get_global_id(0) of
  // the result matrix), lets room for the elements of the vector
  global real* my_out = output + (get_global_id(0) * dim);
  
  // rmvnorm internally calls core_cholesky_compact(Sigma_L, dim)!
  int res = rmvnorm(mu, Sigma_L, dim, my_out);
  
  if (res != 0) {
    for (int i = 0; i < dim; ++i) {
      my_out[i] = (real)NAN;
    }
  }
}
