// Rcpp function body

// read input, compare to signature in oclFunction call:
int r_n       = as<int>(n);
int r_size    = as<int>(size);
real_t r_prob;
if(!Rf_isNull(prob))
  r_prob=as<real_t>(prob);
real_t r_mu;
if(!Rf_isNull(mu)){
  r_mu=as<real_t>(mu);
  r_prob=1.0f/r_mu;
}
// Allocate output variables
IntegerVector r_nbinom(r_n);

// read a random number to initialize OpenCL seed
Environment e = Environment::global_env();
std::vector<int> r_seed = e[".Random.seed"];
int base_seed = r_seed[r_seed[1] + 1];

// Create OpenCL variables (Nur Output-Buffer auf der GPU)
Memory<int> Output(*device, r_n);

// create the kernel (base_seed wird als const int übergeben)
Kernel rnbinom(*device, r_n, "nbinom_rng", Output, base_seed, r_size, r_prob);

// 🔥 kernel run
rnbinom.run();

// transfer from device to host
Output.read_from_device();

// read OpenCL variable into Rcpp variable
for(int i=0; i<r_n; ++i) {
  r_nbinom[i] = Output[i];
}

// force random seed update in R session
Function f("runif"); f(1);

// return results
return r_nbinom;
