// -*- mode: C -*-
kernel void geom_q(global int* output, global real* p, const real prob) {
  int id = get_global_id(0);
  output[id] = qgeom(p[id], prob);
}
