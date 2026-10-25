// -*- mode: C -*-
    
kernel void unif_q(global real* output, global real* p, 
                         const real min, const real max) {
  int id = get_global_id(0);
  output[id] = qunif(p[id], min, max);
}
