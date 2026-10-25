// -*- mode: C -*-
kernel void cauchy_cdf(global real* output, global real* q, const real location, const real scale) {
  int id = get_global_id(0);
  output[id] = pcauchy(q[id], location, scale);
}
