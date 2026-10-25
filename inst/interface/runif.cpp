// Rcpp function body

// read input, compare to signature in oclFunction call:
int r_n = as<int>(n);
real r_min        = as<real>(min);
real r_max        = as<real>(max);

// Allocate output variables
NumericVector r_unif(r_n);


// read a random number to initialize OpenCL seed
Environment e = Environment::global_env();
std::vector<int> r_seed = e[".Random.seed"];
int base_seed = r_seed[r_seed[1] + 1];

// Create OpenCL variables, use real instead of flaot or double so it will
// adapt automatically to the hardware capabilies found in your OpenCL device
Memory<real> Output(*device, r_n);



// create the kernel
Kernel runif(*device, r_n, "unif_rng", Output, base_seed, r_min, r_max);

// 🔥 kernel run
runif.run();

// transfer from device to host
Output.read_from_device();

// read OpenCL variable into Rcpp variable
for(int i=0; i<r_n; ++i) {
  r_unif[i]    = Output[i];
}


// force random seed update in R session
Function f("runif"); f(1);


// return results
return r_unif;

