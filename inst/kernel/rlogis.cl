// -*- mode: C -*-
kernel void logis_rng(global real* output, const int seed, const real location, const real scale) {
  INIT_MT(seed);
  output[get_global_id(0)] = rlogis(location, scale);
}
