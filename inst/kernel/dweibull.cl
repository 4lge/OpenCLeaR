// -*- mode: C -*-
kernel void weibull_pdf(global real* output, global real* x, const real shape, const real scale) {
  int id = get_global_id(0);
  output[id] = dweibull(x[id], shape, scale);
}
