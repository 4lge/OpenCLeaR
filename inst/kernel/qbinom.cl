// -*- mode: C -*-
kernel void binom_q(global int* output, global real* p, const int size, const real prob) {
  int id = get_global_id(0);
  output[id] = qbinom(p[id], size, prob);
}
