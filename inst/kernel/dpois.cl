// -*- mode: C -*-
kernel void pois_pdf(global real* output, global real* x, const real lambda) {
  int id = get_global_id(0);
  output[id] = dpois(x[id], lambda);
}
