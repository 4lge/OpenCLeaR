// -*- mode: C -*-
kernel void weibull_rng(global real* output, const int seed, const real shape, const real scale) {
  INIT_MT(seed);
  output[get_global_id(0)] = rweibull(shape, scale);
}
