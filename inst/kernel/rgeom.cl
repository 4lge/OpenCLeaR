// -*- mode: C -*-
kernel void geom_rng(global int* output, const int seed, const real prob) {
  INIT_MT(seed);
  output[get_global_id(0)] = rgeom(prob);
}
