// -*- mode: C -*-
kernel void hyper_cdf(global real* output, global real* q, const int m, const int n, const int k) {
  int id = get_global_id(0);
  output[id] = phyper(q[id], m, n, k);
}
