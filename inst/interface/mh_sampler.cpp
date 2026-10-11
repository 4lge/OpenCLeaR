// Rcpp function body

// read input, compare to signature in oclFunction call:
int total_samples = as<int>(n_samples);
int chains        = as<int>(n_chains);
int samples_per_chain = total_samples / chains;

NumericVector r_data(data_vector);
int data_len = r_data.size();
int total_output_size = chains * samples_per_chain;

// Allocate output variables
NumericVector out_mu(total_output_size);
NumericVector out_sigma(total_output_size);

// read a random number to initialize OpenCL seed
Environment e = Environment::global_env();
std::vector<int> r_seed = e[".Random.seed"];
int base_seed = r_seed[r_seed[1] + 1];

// Create OpenCL variables, use real_t instead of flaot or double so it will
// adapt automatically to the hardware capabilies found in your OpenCL device
Memory<real_t> GpuData(*device, data_len);
Memory<real_t> GpuMu(*device, total_output_size);
Memory<real_t> GpuSigma(*device, total_output_size);
Memory<int>    GpuSeeds(*device, chains);

// fill OpenCL variables
for(int i=0; i<data_len; ++i) GpuData[i] = (real_t)r_data[i];
for(int i=0; i<chains; ++i)   GpuSeeds[i] = base_seed + (i * 777);


// transfer from host to device
GpuData.write_to_device();
GpuSeeds.write_to_device();

// Create remaining kernel arguments, avoid constants, instead assign them to real_t variables
// for automatic float/double assignment
real_t mu_init_typed       = as<real_t>(mu_init);
real_t sigma_init_typed    = as<real_t>(sigma_init);
real_t prop_sd_mu_typed    = (real_t)0.05;
real_t prop_sd_sigma_typed = (real_t)0.05;

// create the kernel
Kernel mh_kernel(*device, chains, "mh_sampler_kernel", 
                 GpuMu, GpuSigma, GpuData, data_len, samples_per_chain,
                 mu_init_typed, sigma_init_typed, prop_sd_mu_typed,  prop_sd_sigma_typed , GpuSeeds);

// 🔥 kernel run
mh_kernel.run();

// transfer from device to host
GpuMu.read_from_device();
GpuSigma.read_from_device();

// read OpenCL variable into Rcpp variable
for(int i=0; i<total_output_size; ++i) {
    out_mu[i]    = GpuMu[i];
    out_sigma[i] = GpuSigma[i];
}

// force random seed update in R session
Function f("runif"); f(1);


// return results
return List::create(
    _["mu"]    = out_mu,
    _["sigma"] = out_sigma
);
