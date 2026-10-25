// -*- mode: C -*-
kernel void nbinom_pdf(global real* output, global real* x, const int size, const real prob) {
  int id = get_global_id(0);
  output[id] = dnbinom(x[id], size, prob);
}
