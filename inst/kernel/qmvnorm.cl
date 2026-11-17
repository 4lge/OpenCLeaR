// -*- mode: C -*-

kernel void mvnorm_quant_mc(global real* output, const int seed,
                            const real p, global const real* mu, global real* Sigma_L,
                            const int dim, const int tail_mode, const int n_per_thread) {
  int gid = get_global_id(0);
  INIT_MT(seed);

  real ws_l[64];
  real ws_u[64];
  real ws_p[64];

  output[gid] = qmvnorm(p, mu, Sigma_L, dim, tail_mode, n_per_thread, ws_l, ws_u, ws_p);
}
