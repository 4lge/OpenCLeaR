// -*- mode: C -*-
kernel void invgamma_rng(global real* output, const int seed, const real shape, const real rate) {
  INIT_MT(seed);
  output[get_global_id(0)] = rinvgamma(shape, rate);
}
