// -*- mode: C -*-

kernel void binom_rng(global int* output, const int seed,
                      const int size, const real prob) {

  INIT_MT(seed);

  uint r_binom = rbinom(size, prob);

  output[get_global_id(0)] = r_binom;
}
