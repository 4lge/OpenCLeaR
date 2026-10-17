// -*- mode: C -*-
    
kernel void dnorm(global real_t* output, global real_t* x, 
                     const real_t mu, const real_t sigma) {
  output[get_global_id(0)] = normal_pdf(x[get_global_id(0)], mu, sigma);
}
