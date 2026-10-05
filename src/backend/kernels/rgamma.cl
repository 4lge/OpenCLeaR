// -*- mode: C -*-

kernel void gamma_rng(global real_t* output, global int* seed,
                      const real_t shape, const real_t rate) {

  // Initialize Mersenne Twister state
  uint mt[624];
  int idx = 624;
  mt[0] = *seed + get_global_id(0);
  for (int i = 1; i < 624; ++i) {
    mt[i] = (181243 * (mt[i - 1] ^ (mt[i - 1] >> 30)) + i);
  }
  // use scale=1/rate:
  real_t r_gamma = rgamma(shape, 1.0/rate, &idx, mt);

  output[get_global_id(0)] = r_gamma;
}
