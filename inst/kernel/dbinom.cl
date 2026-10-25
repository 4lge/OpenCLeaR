// -*- mode: C -*-
kernel void binom_pdf(global real* output, global real* x, const real size, const real prob) {
  int id = get_global_id(0);
  output[id] = dbinom(x[id], size, prob);
}
