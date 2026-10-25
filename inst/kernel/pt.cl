// -*- mode: C -*-
kernel void t_cdf(global real* output, global real* q, const int df) {
  int id = get_global_id(0);
  output[id] = pt(q[id], df);
}
