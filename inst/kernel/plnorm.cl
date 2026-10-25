// -*- mode: C -*-
kernel void lnorm_cdf(global real* output, global real* q, const real meanlog, const real sdlog) {
  int id = get_global_id(0);
  output[id] = plnorm(q[id], meanlog, sdlog);
}
