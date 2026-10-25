// -*- mode: C -*-
kernel void pois_q(global int* output, global real* p, const real lambda) {
  int id = get_global_id(0);
  output[id] = qpois(p[id], lambda);
}
