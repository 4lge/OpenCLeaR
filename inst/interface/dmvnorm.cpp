// Rcpp function body

// 1. Read inputs
NumericMatrix r_x(x);
NumericVector r_mean(mean);
NumericMatrix r_cov(sigma);
int r_log = as<bool>(log) ? 1 : 0;

int r_n = r_x.nrow();
int dim = r_mean.size();

if (r_x.ncol() != dim || r_cov.nrow() != dim || r_cov.ncol() != dim) {
  stop("Dimensions of 'x', 'mean' and 'sigma' do not match!");
}
if (dim > 64) {
  stop("Currently a maximum of 64 dimensions are supported in the kernel.");
}

// 2. Allocate OpenCL input buffer
Memory<real> X_in(*device, r_n * dim);
Memory<real> Mean(*device, dim);
Memory<real> Sigma_L(*device, dim * dim + 1); // +1 for dirty flag

// Pack observation matrix X row by row (row major) for the GPU
for (int i = 0; i < r_n; ++i) {
  for (int j = 0; j < dim; ++j) {
    X_in[i * dim + j] = (real)r_x(i, j);
  }
}

// Fill mean and upper triangle of sigma
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
Sigma_L[dim * dim] = (real)-1.0f; // Set dirty flag

X_in.write_to_device();
Mean.write_to_device();
Sigma_L.write_to_device();

// 3. allocate Output buffer
Memory<real> Output(*device, r_n);

// 4. Start kernel (r_n threads, one per line of x)
Kernel dmvnorm_kernel(*device, r_n, "mvnorm_pdf", Output, X_in, Mean, Sigma_L, dim, r_log);
dmvnorm_kernel.run();

// 5. Retrieve results
Output.read_from_device();

NumericVector res(r_n);
for (int i = 0; i < r_n; ++i) {
  res[i] = Output[i];
}

return res;
