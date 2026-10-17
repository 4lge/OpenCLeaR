// Rcpp function body

// read input, compare to signature in oclFunction call:
int r_n        = as<int>(n);
real_t r_mean  = as<real_t>(mean);
real_t r_sd    = as<real_t>(sd);

// Allocate output variables
NumericVector r_norm(r_n);

// read a random number to initialize OpenCL seed
Environment e = Environment::global_env();
std::vector<int> r_seed = e[".Random.seed"];
int base_seed = r_seed[r_seed[1] + 1];

// Create OpenCL variables (Nur Output-Buffer auf der GPU)
Memory<real_t> Output(*device, r_n);

// create the kernel (base_seed wird als const int übergeben)
Kernel rnorm(*device, r_n, "norm_rng", Output, base_seed, r_mean, r_sd);

// 🔥 kernel run
rnorm.run();

// transfer from device to host
Output.read_from_device();

// read OpenCL variable into Rcpp variable
for(int i=0; i<r_n; ++i) {
  r_norm[i] = Output[i];
}

// force random seed update in R session
Function f("runif"); f(1);

// return results
return r_norm;
