// -*- mode: C -*-
kernel void pinvgamma_kernel(global real* output, global const real* q, const real shape, const real rate, const int n) {
  int i = get_global_id(0);
  if (i >= n) return;
  output[i] = pinvgamma(q[i], shape, rate);
}
