// -*- mode: C -*-
kernel void logis_cdf(global real* output, global real* q, const real location, const real scale) {
  int id = get_global_id(0);
  output[id] = plogis(q[id], location, scale);
}
