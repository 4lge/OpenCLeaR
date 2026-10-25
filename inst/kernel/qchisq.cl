// -*- mode: C -*-
kernel void chisq_q(global real* output, global real* p, const int df) {
  int id = get_global_id(0);
  output[id] = qchisq(p[id], df);
}
