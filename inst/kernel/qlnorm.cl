// -*- mode: C -*-
kernel void lnorm_q(global real* output, global real* p, const real meanlog, const real sdlog) {
  int id = get_global_id(0);
  output[id] = qlnorm(p[id], meanlog, sdlog);
}
