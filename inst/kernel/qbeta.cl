// -*- mode: C -*-
kernel void beta_q(global real* output, global real* p, const real shape1, const real shape2) {
  int id = get_global_id(0);
  output[id] = qbeta(p[id], shape1, shape2);
}
