// -*- mode: C -*-

kernel void hyper_rng(global int* output, const int seed,
                      const int size, const int white, const int black ) {

  // Initialize Mersenne Twister state
  uint mt[624];
  int idx = 624;
  mt[0] = seed + get_global_id(0);
  for (int i = 1; i < 624; ++i) {
    mt[i] = (181243 * (mt[i - 1] ^ (mt[i - 1] >> 30)) + i);
  }

  uint r_hyperg = rhyper(size, white, black, &idx, mt);

  output[get_global_id(0)] = r_hyperg;
}
