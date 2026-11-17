// Rcpp function body

// 1. Read inputs
NumericVector r_lower(lower);
NumericVector r_upper(upper);
NumericVector r_mean(mean);
NumericMatrix r_cov(sigma);
int r_n = as<int>(n);

int dim = r_mean.size();
if (r_lower.size() != dim || r_upper.size() != dim || 
    r_cov.nrow() != dim || r_cov.ncol() != dim) {
  stop("Dimensions of 'lower', 'upper', 'mean' and 'sigma' do not match!");
}
if (dim > 64) {
  stop("Currently a maximum of 64 dimensions are supported in the kernel.");
}

// 2. Get seed from R
Environment e = Environment::global_env();
if (!e.exists(".Random.seed")) {
  Function f("runif"); f(1);
}
std::vector<int> r_seed = e[".Random.seed"];
int base_seed = r_seed[r_seed[1] + 1];

// 3. Divide work between GPU threads (4096 threads)
int n_threads = 4096;
if (r_n < n_threads) n_threads = r_n;
int n_per_thread = std::max(1, r_n / n_threads);
long long total_samples = (long long)n_threads * (long long)n_per_thread;

// 4. Allocate & fill GPU buffer
Memory<real> Lower(*device, dim);
Memory<real> Upper(*device, dim);
Memory<real> Mean(*device, dim);
Memory<real> Sigma_L(*device, dim * dim + 1); // +1 for dirty flag

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
Sigma_L[dim * dim] = (real)-1.0f; // Set dirty flag

Lower.write_to_device();
Upper.write_to_device();
Mean.write_to_device();
Sigma_L.write_to_device();

// Output buffer: A real value (proportion of hits) per thread
Memory<real> Probs(*device, n_threads);

// 5. Start kernel
Kernel pmvnorm_kernel(*device, n_threads, "mvnorm_cdf_mc", 
                      Probs, base_seed, Lower, Upper, Mean, Sigma_L, dim, n_per_thread);
pmvnorm_kernel.run();

// 6. Average results in 64-bit double
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

// Update R seed
Function f("runif"); f(1);

return res;
