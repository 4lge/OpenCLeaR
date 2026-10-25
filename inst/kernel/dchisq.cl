// -*- mode: C -*-
kernel void chisq_pdf(global real* output, global real* x, const int df) {
  int id = get_global_id(0);
  output[id] = dchisq(x[id], df);
}
