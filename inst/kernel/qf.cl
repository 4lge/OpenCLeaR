// -*- mode: C -*-
kernel void f_q(global real* output, global real* p, const int df1, const int df2) {
  int id = get_global_id(0);
  output[id] = qf(p[id], df1, df2);
}
