// -*- mode: C -*-
    
kernel void norm_pdf(global real* output, global real* x, 
                     const real mu, const real sigma) {
  output[get_global_id(0)] = dnorm(x[get_global_id(0)], mu, sigma);
}
