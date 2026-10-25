// -*- mode: C -*-
kernel void geom_cdf(global real* output, global real* q, const real prob) {
  int id = get_global_id(0);
  output[id] = pgeom(q[id], prob);
}
