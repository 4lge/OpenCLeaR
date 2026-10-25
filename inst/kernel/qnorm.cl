// -*- mode: C -*-
    
kernel void norm_q(global real* output, global real* p, 
                         const real mu, const real sigma) {
  int id = get_global_id(0);
  output[id] = qnorm(p[id], mu, sigma);
}
