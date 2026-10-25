// -*- mode: C -*-
kernel void t_q(global real* output, global real* p, const int df) {
  int id = get_global_id(0);
  output[id] = qt(p[id], df);
}
