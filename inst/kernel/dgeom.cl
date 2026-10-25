// -*- mode: C -*-
kernel void geom_pdf(global real* output, global real* x, const real prob) {
  int id = get_global_id(0);
  output[id] = dgeom(x[id], prob);
}
