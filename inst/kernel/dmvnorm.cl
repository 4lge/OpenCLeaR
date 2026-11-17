// -*- mode: C -*-

kernel void mvnorm_pdf(global real* output, global const real* x, 
                       global const real* mu, global real* Sigma_L, 
                       const int dim, const int log_pdf) {
  int gid = get_global_id(0);
  
  // Pointer auf die gid-te Beobachtung (Zeile gid der n x dim Eingabematrix)
  global const real* my_x = x + (gid * dim);
  
  real ws[64]; // Privater Workspace für die Vorwärtssubstitution
  output[gid] = dmvnorm(my_x, mu, Sigma_L, dim, log_pdf, ws);
}
