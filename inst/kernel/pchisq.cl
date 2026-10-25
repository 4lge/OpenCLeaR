// -*- mode: C -*-
kernel void chisq_cdf(global real* output, global real* q, const int df) {
  int id = get_global_id(0);
  output[id] = pchisq(q[id], df);
}
