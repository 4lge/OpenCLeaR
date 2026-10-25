// -*- mode: C -*-
kernel void nbinom_q(global int* output, global real* p, const int size, const real prob) {
  int id = get_global_id(0);
  output[id] = qnbinom(p[id], size, prob);
}
