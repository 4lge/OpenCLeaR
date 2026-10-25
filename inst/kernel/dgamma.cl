// -*- mode: C -*-
kernel void gamma_pdf(global real* output, global real* x, const real shape, const real rate) {
  int id = get_global_id(0);
  output[id] = dgamma(x[id], shape, rate);
}
