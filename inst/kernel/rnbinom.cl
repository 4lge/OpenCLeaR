// -*- mode: C -*-
kernel void nbinom_rng(global int* output, const int seed, const int size, const real prob) {
  INIT_MT(seed);
  output[get_global_id(0)] = rnbinom(size, prob);
}
