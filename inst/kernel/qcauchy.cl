// -*- mode: C -*-
kernel void cauchy_q(global real* output, global real* p, const real location, const real scale) {
  int id = get_global_id(0);
  output[id] = qcauchy(p[id], location, scale);
}
