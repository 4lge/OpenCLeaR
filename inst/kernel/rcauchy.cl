// -*- mode: C -*-
kernel void cauchy_rng(global real* output, const int seed, const real location, const real scale) {
  INIT_MT(seed);
  output[get_global_id(0)] = rcauchy(location, scale);
}
