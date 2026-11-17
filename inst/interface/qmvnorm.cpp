// Rcpp function body (reiner Test-Harness für tinytest)
real r_p = as<real>(p);
NumericVector r_mean(mean);
NumericMatrix r_cov(sigma);
std::string r_tail = as<std::string>(tail);
int r_n = as<int>(n);

int tail_mode = 0;
if (r_tail == "lower.tail")      tail_mode = 0;
else if (r_tail == "upper.tail") tail_mode = 1;
else if (r_tail == "both.tails") tail_mode = 2;
else stop("Erlaubte Werte fuer 'tail': 'lower.tail', 'upper.tail', 'both.tails'");

int dim = r_mean.size();
if (r_cov.nrow() != dim || r_cov.ncol() != dim) stop("Dimensionen stimmen nicht ueberein!");
if (dim > 64) stop("Maximal 64 Dimensionen im Test-Kernel.");

Environment e = Environment::global_env();
if (!e.exists(".Random.seed")) { Function f("runif"); f(1); }
std::vector<int> r_seed = e[".Random.seed"];
int base_seed = r_seed[r_seed[1] + 1];

// Aufteilen auf 256 parallele GPU-Threads, jeder führt qmvnorm() komplett auf der GPU aus
int n_threads = 256;
int n_per_thread = std::max(1000, r_n / n_threads);

Memory<real> Mean(*device, dim);
Memory<real> Sigma_L(*device, dim * dim + 1);
for (int i = 0; i < dim; ++i) {
  Mean[i] = (real)r_mean[i];
  for (int j = 0; j < dim; ++j) {
    Sigma_L[i * dim + j] = (j >= i) ? (real)r_cov(i, j) : (real)0.0;
  }
}
Sigma_L[dim * dim] = (real)-1.0f;

Mean.write_to_device();
Sigma_L.write_to_device();

Memory<real> Output(*device, n_threads);
Kernel qmvnorm_kernel(*device, n_threads, "mvnorm_quant_mc",
                      Output, base_seed, r_p, Mean, Sigma_L, dim, tail_mode, n_per_thread);
qmvnorm_kernel.run();
Output.read_from_device();

double sum_q = 0.0;
for (int i = 0; i < n_threads; ++i) {
  sum_q += (double)Output[i];
}

Function f("runif"); f(1);
return NumericVector::create(sum_q / (double)n_threads);
