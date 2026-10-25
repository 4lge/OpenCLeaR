// -*- mode: C -*-
kernel void hyper_pdf(global real* output, global real* x, const real m, const real n, const real k) {
  int id = get_global_id(0);
  output[id] = dhyper(x[id], m, n, k);
}
