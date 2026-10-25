// -*- mode: C -*-
kernel void gamma_cdf(global real* output, global real* q, const real shape, const real rate) {
  int id = get_global_id(0);
  output[id] = pgamma(q[id], shape, rate);
}
