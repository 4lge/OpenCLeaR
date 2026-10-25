// -*- mode: C -*-
kernel void gamma_rng(global real* output, const int seed, const real shape, const real rate) {
  INIT_MT(seed);
  output[get_global_id(0)] = rgamma(shape, rate);
}
