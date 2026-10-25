// -*- mode: C -*-
kernel void lnorm_rng(global real* output, const int seed, const real meanlog, const real sdlog) {
  INIT_MT(seed);
  output[get_global_id(0)] = rlnorm(meanlog, sdlog);
}
