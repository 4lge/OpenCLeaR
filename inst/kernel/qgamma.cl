// -*- mode: C -*-
kernel void gamma_q(global real* output, global real* p, const real shape, const real rate) {
  int id = get_global_id(0);
  output[id] = qgamma(p[id], shape, rate);
}
