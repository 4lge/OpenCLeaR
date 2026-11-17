// Rcpp function body

// 1. Inputs einlesen
NumericMatrix r_x(x);
NumericVector r_mean(mean);
NumericMatrix r_cov(sigma);
int r_log = as<bool>(log) ? 1 : 0;

int r_n = r_x.nrow();
int dim = r_mean.size();

if (r_x.ncol() != dim || r_cov.nrow() != dim || r_cov.ncol() != dim) {
  stop("Dimensionen von 'x', 'mean' und 'sigma' stimmen nicht ueberein!");
}
if (dim > 64) {
  stop("Aktuell werden im Kernel maximal 64 Dimensionen unterstuetzt.");
}

// 2. OpenCL Input-Buffer allokieren
Memory<real> X_in(*device, r_n * dim);
Memory<real> Mean(*device, dim);
Memory<real> Sigma_L(*device, dim * dim + 1); // +1 für Dirty-Flag

// Beobachtungsmatrix X zeilenweise (Row-Major) für die GPU verpacken
for (int i = 0; i < r_n; ++i) {
  for (int j = 0; j < dim; ++j) {
    X_in[i * dim + j] = (real)r_x(i, j);
  }
}

// Mittelwert und oberes Dreieck von Sigma füllen
for (int i = 0; i < dim; ++i) {
  Mean[i] = (real)r_mean[i];
  for (int j = 0; j < dim; ++j) {
    if (j >= i) {
      Sigma_L[i * dim + j] = (real)r_cov(i, j);
    } else {
      Sigma_L[i * dim + j] = (real)0.0;
    }
  }
}
Sigma_L[dim * dim] = (real)-1.0f; // Dirty-Flag setzen

X_in.write_to_device();
Mean.write_to_device();
Sigma_L.write_to_device();

// 3. Output-Buffer allokieren
Memory<real> Output(*device, r_n);

// 4. Kernel starten (r_n Threads, einer pro Zeile von x)
Kernel dmvnorm_kernel(*device, r_n, "mvnorm_pdf", Output, X_in, Mean, Sigma_L, dim, r_log);
dmvnorm_kernel.run();

// 5. Ergebnisse zurückholen
Output.read_from_device();

NumericVector res(r_n);
for (int i = 0; i < r_n; ++i) {
  res[i] = Output[i];
}

return res;
