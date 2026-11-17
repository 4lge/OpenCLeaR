// -*- mode: C -*-

kernel void mvnorm_pdf(global real* output, global const real* x, 
                       global const real* mu, global real* Sigma_L, 
                       const int dim, const int log_pdf) {
  int gid = get_global_id(0);
  
  // Pointer to the gid-th observation (row gid of the n x dim input matrix)
  global const real* my_x = x + (gid * dim);
  
  real ws[64]; // Private workspace for forward substitution
  output[gid] = dmvnorm(my_x, mu, Sigma_L, dim, log_pdf, ws);
}
