// -*- mode: C -*-

kernel void beta_rng(global real_t* output, global int* seed,
                     const real_t alpha, const real_t beta) {

  // Initialize Mersenne Twister state
  uint mt[624];
  int idx = 624;
  mt[0] = *seed + get_global_id(0);
  for (int i = 1; i < 624; ++i) {
    mt[i] = (181243 * (mt[i - 1] ^ (mt[i - 1] >> 30)) + i);
  }

  real_t r_beta = rbeta(alpha, beta, &idx, mt);

  output[get_global_id(0)] = r_beta;
}
