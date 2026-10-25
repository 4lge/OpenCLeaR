// -*- mode: C -*-
kernel void f_rng(global real* output, const int seed, const int df1, const int df2) {
  INIT_MT(seed);
  output[get_global_id(0)] = rf(df1, df2);
}
