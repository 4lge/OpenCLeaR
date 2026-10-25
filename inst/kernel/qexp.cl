// -*- mode: C -*-
kernel void exp_q(global real* output, global real* p, const real rate) {
  int id = get_global_id(0);
  output[id] = qexp(p[id], rate);
}
