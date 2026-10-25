// -*- mode: C -*-
kernel void beta_cdf(global real* output, global real* q, const real shape1, const real shape2) {
  int id = get_global_id(0);
  output[id] = pbeta(q[id], shape1, shape2);
}
