// Rcpp function body

// read input, compare to signature in oclFunction call:
int r_nn = as<int>(nn);
int r_m  = as<int>(m);
int r_n  = as<int>(n);
int r_k  = as<int>(k);

// Allocate output variables
IntegerVector r_hyper(r_nn);

// read a random number to initialize OpenCL seed
Environment e = Environment::global_env();
std::vector<int> r_seed = e[".Random.seed"];
int base_seed = r_seed[r_seed[1] + 1];

// Create OpenCL variables (Nur Output-Buffer auf der GPU)
Memory<int> Output(*device, r_nn);

// create the kernel (base_seed wird als const int übergeben)
Kernel rhyper(*device, r_nn, "hyper_rng", Output, base_seed, r_m, r_n, r_k);

// 🔥 kernel run
rhyper.run();

// transfer from device to host
Output.read_from_device();

// read OpenCL variable into Rcpp variable
for(int i=0; i<r_nn; ++i) {
  r_hyper[i] = Output[i];
}

// force random seed update in R session
Function f("runif"); f(1);

// return results
return r_hyper;
