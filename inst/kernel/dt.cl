// -*- mode: C -*-
kernel void t_pdf(global real* output, global real* x, const int df) {
  int id = get_global_id(0);
  output[id] = dt(x[id], df);
}
