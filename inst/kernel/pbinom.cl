// -*- mode: C -*-
kernel void binom_cdf(global real* output, global real* q, const real size, const real prob) {
  int id = get_global_id(0);
  output[id] = pbinom(q[id], size, prob);
}
