// -*- mode: C -*-
kernel void cauchy_pdf(global real* output, global real* x, const real location, const real scale) {
  int id = get_global_id(0);
  output[id] = dcauchy(x[id], location, scale);
}
