// -*- mode: C -*-
kernel void weibull_q(global real* output, global real* p, const real shape, const real scale) {
  int id = get_global_id(0);
  output[id] = qweibull(p[id], shape, scale);
}
