// -*- mode: C -*-
kernel void beta_rng(global real* output, const int seed, const real shape1, const real shape2) {
  INIT_MT(seed);
  output[get_global_id(0)] = rbeta(shape1, shape2);
}
