// -*- mode: C -*-
kernel void hyper_rng(global int* output, const int seed, const int m, const int n, const int k) {
  INIT_MT(seed);
  output[get_global_id(0)] = rhyper(m, n, k);
}
