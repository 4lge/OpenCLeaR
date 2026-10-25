// -*- mode: C -*-
kernel void exp_rng(global real* output, const int seed, const real rate) {
  INIT_MT(seed);
  output[get_global_id(0)] = rexp(rate);
}
