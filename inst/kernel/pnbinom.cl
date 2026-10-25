// -*- mode: C -*-
kernel void nbinom_cdf(global real* output, global real* q, const int size, const real prob) {
  int id = get_global_id(0);
  output[id] = pnbinom(q[id], size, prob);
}
