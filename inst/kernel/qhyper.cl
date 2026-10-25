// -*- mode: C -*-
kernel void hyper_q(global int* output, global real* p, const int m, const int n, const int k) {
  int id = get_global_id(0);
  output[id] = qhyper(p[id], m, n, k);
}
