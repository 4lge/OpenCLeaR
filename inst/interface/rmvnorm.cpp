// Rcpp function body

// read input, compare to signature in oclFunction call:
int r_n = as<int>(n);
NumericVector r_mean(mean);
NumericMatrix r_cov(sigma);
int dim = r_mean.size();

if (r_cov.nrow() != dim || r_cov.ncol() != dim) {
  stop("Dimensionen von 'mean' und 'sigma' stimmen nicht ueberein!");
}

// Allocate output variables (r_n Zeilen, dim Spalten)
NumericMatrix r_norm(r_n, dim);

// read a random number to initialize OpenCL seed
Environment e = Environment::global_env();
std::vector<int> r_seed = e[".Random.seed"];
int base_seed = r_seed[r_seed[1] + 1];

// Create OpenCL variables (input buffer on the GPU)
Memory<real> Mean(*device, dim);
Memory<real> Sigma_L(*device, dim * dim + 1); // +1 for the dirty flag

// fill GPU vars with input (Row-Major: row i, column j)
for (int i = 0; i < dim; ++i) {
  Mean[i] = (real)r_mean[i];
  for (int j = 0; j < dim; ++j) {
    if (j >= i) { // upper triangle incl. diagonal (j >= i)
      Sigma_L[i * dim + j] = (real)r_cov(i, j);
    } else {
      Sigma_L[i * dim + j] = (real)0.0;
    }
  }
}
Sigma_L[dim * dim] = (real)-1.0f; // mark dirty

Mean.write_to_device();
Sigma_L.write_to_device();

// Create OpenCL variables (output buffer for r_n vectors of length dim)
Memory<real> Output(*device, r_n * dim);

// create the kernel (inkl. dim als const int!)
Kernel mvnorm(*device, r_n, "mvnorm_rng", Output, base_seed, Mean, Sigma_L, dim);

// 🔥 kernel run
mvnorm.run();

// transfer from device to host
Output.read_from_device();

// read OpenCL variable into Rcpp variable
for (int i = 0; i < r_n; ++i) {
  for (int j = 0; j < dim; ++j) {
    r_norm(i, j) = Output[i * dim + j];
  }
}

// force random seed update in R session
Function f("runif"); f(1);

// return results
return r_norm;
