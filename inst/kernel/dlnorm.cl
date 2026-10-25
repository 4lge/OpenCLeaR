// -*- mode: C -*-
kernel void lnorm_pdf(global real* output, global real* x, const real meanlog, const real sdlog) {
  int id = get_global_id(0);
  output[id] = dlnorm(x[id], meanlog, sdlog);
}
