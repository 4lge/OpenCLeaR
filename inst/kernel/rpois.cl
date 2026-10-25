// -*- mode: C -*-

kernel void pois_rng(global int* output, const int seed,
                     const real lambda) {

  INIT_MT(seed);
 
  uint r_pois = rpois(lambda);

  output[get_global_id(0)] = r_pois;
}
