// -*- mode: C -*-
kernel void f_cdf(global real* output, global real* q, const int df1, const int df2) {
  int id = get_global_id(0);
  output[id] = pf(q[id], df1, df2);
}
