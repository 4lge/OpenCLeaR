// -*- mode: C -*-
kernel void exp_cdf(global real* output, global real* q, const real rate) {
  int id = get_global_id(0);
  output[id] = pexp(q[id], rate);
}
