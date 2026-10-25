// -*- mode: C -*-
kernel void logis_pdf(global real* output, global real* x, const real location, const real scale) {
  int id = get_global_id(0);
  output[id] = dlogis(x[id], location, scale);
}
