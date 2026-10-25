// -*- mode: C -*-
    
kernel void norm_cdf(global real* output, global real* q, 
                  const real mu, const real sigma) {
  int id = get_global_id(0);
  output[id] = pnorm(q[id], mu, sigma);
}
