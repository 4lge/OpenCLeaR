// -*- mode: C -*-
kernel void chisq_rng(global real* output, const int seed, const int df) {
  INIT_MT(seed);
  output[get_global_id(0)] = rchisq(df);
}


