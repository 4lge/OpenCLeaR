// -*- mode: C -*-
    
kernel void unif_pdf(global real* output, global real* x, 
                     const real min, const real max) {
  output[get_global_id(0)] = dunif(x[get_global_id(0)], min, max);
}
