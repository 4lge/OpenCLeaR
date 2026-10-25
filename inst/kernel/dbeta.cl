// -*- mode: C -*-
kernel void beta_pdf(global real* output, global real* x, const real shape1, const real shape2) {
  int id = get_global_id(0);
  output[id] = dbeta(x[id], shape1, shape2);
}
