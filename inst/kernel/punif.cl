// -*- mode: C -*-
    
kernel void unif_cdf(global real* output, global real* q, 
                  const real min, const real max) {
  int id = get_global_id(0);
  output[id] = punif(q[id], min, max);
}
