// Rcpp function body

// 1. Inputs einlesen
NumericVector r_lower(lower);
NumericVector r_upper(upper);
NumericVector r_mean(mean);
NumericMatrix r_cov(sigma);
int r_n = as<int>(n);

int dim = r_mean.size();
if (r_lower.size() != dim || r_upper.size() != dim || 
    r_cov.nrow() != dim || r_cov.ncol() != dim) {
  stop("Dimensionen von 'lower', 'upper', 'mean' und 'sigma' stimmen nicht ueberein!");
}
if (dim > 64) {
  stop("Aktuell werden im Kernel maximal 64 Dimensionen unterstuetzt.");
}

// 2. Seed aus R holen
Environment e = Environment::global_env();
if (!e.exists(".Random.seed")) {
  Function f("runif"); f(1);
}
std::vector<int> r_seed = e[".Random.seed"];
int base_seed = r_seed[r_seed[1] + 1];

// 3. Arbeit auf GPU-Threads aufteilen (4096 Threads)
int n_threads = 4096;
if (r_n < n_threads) n_threads = r_n;
int n_per_thread = std::max(1, r_n / n_threads);
long long total_samples = (long long)n_threads * (long long)n_per_thread;

// 4. GPU-Buffer allokieren & befüllen
Memory<real> Lower(*device, dim);
Memory<real> Upper(*device, dim);
Memory<real> Mean(*device, dim);
Memory<real> Sigma_L(*device, dim * dim + 1); // +1 für Dirty-Flag

for (int i = 0; i < dim; ++i) {
  Lower[i] = (real)r_lower[i];
  Upper[i] = (real)r_upper[i];
  Mean[i]  = (real)r_mean[i];
  
  for (int j = 0; j < dim; ++j) {
    if (j >= i) {
      Sigma_L[i * dim + j] = (real)r_cov(i, j);
    } else {
      Sigma_L[i * dim + j] = (real)0.0;
    }
  }
}
Sigma_L[dim * dim] = (real)-1.0f; // Dirty-Flag setzen

Lower.write_to_device();
Upper.write_to_device();
Mean.write_to_device();
Sigma_L.write_to_device();

// Output-Buffer: Ein real-Wert (Anteil Treffer) pro Thread
Memory<real> Probs(*device, n_threads);

// 5. Kernel starten
Kernel pmvnorm_kernel(*device, n_threads, "mvnorm_cdf_mc", 
                      Probs, base_seed, Lower, Upper, Mean, Sigma_L, dim, n_per_thread);
pmvnorm_kernel.run();

// 6. Ergebnisse in 64-Bit double mitteln
Probs.read_from_device();

double sum_probs = 0.0;
for (int i = 0; i < n_threads; ++i) {
  sum_probs += (double)Probs[i];
}

double prob = sum_probs / (double)n_threads;
double mc_error = std::sqrt(prob * (1.0 - prob) / (double)total_samples);

NumericVector res = NumericVector::create(prob);
res.attr("error")   = mc_error;
res.attr("samples") = (double)total_samples;

// R-Seed aktualisieren
Function f("runif"); f(1);

return res;
