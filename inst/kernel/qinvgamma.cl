// -*- mode: C -*-
kernel void qinvgamma_kernel(global real* output, global const real* p, const real shape, const real rate, const int n) {
  int i = get_global_id(0);
  if (i >= n) return;
  output[i] = qinvgamma(p[i], shape, rate);
}
