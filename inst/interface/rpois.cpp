// Rcpp function body

// read input, compare to signature in oclFunction call:
int r_n         = as<int>(n);
real_t r_lambda = as<real_t>(lambda);

// Allocate output variables
IntegerVector r_pois(r_n);

// read a random number to initialize OpenCL seed
Environment e = Environment::global_env();
std::vector<int> r_seed = e[".Random.seed"];
int base_seed = r_seed[r_seed[1] + 1];

// Create OpenCL variables (Nur Output-Buffer auf der GPU)
Memory<int> Output(*device, r_n);

// create the kernel (base_seed wird als const int übergeben)
Kernel rpois(*device, r_n, "pois_rng", Output, base_seed, r_lambda);

// 🔥 kernel run
rpois.run();

// transfer from device to host
Output.read_from_device();

// read OpenCL variable into Rcpp variable
for(int i=0; i<r_n; ++i) {
  r_pois[i] = Output[i];
}

// force random seed update in R session
Function f("runif"); f(1);

// return results
return r_pois;
