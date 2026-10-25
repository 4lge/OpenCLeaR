// -*- mode: C -*-
kernel void f_pdf(global real* output, global real* x, const int df1, const int df2) {
  int id = get_global_id(0);
  output[id] = df(x[id], df1, df2);
}
