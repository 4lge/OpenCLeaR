// -*- mode: C -*-
kernel void exp_pdf(global real* output, global real* x, const real rate) {
  int id = get_global_id(0);
  output[id] = dexp(x[id], rate);
}
