// -*- mode: C -*-
kernel void dinvgamma_kernel(global real* output, global const real* x, const real shape, const real rate, const int n) {
  int i = get_global_id(0);
  if (i >= n) return;
  output[i] = dinvgamma(x[i], shape, rate);
}
