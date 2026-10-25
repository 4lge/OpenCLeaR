// -*- mode: C -*-
kernel void pois_cdf(global real* output, global real* q, const real lambda) {
  int id = get_global_id(0);
  output[id] = ppois(q[id], lambda);
}
