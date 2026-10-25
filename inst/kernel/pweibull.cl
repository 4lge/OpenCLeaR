// -*- mode: C -*-
kernel void weibull_cdf(global real* output, global real* q, const real shape, const real scale) {
  int id = get_global_id(0);
  output[id] = pweibull(q[id], shape, scale);
}
