// Rcpp function body
int r_n             = as<int>(n);
real r_meanlog      = as<real>(meanlog);
real r_sdlog        = as<real>(sdlog);

NumericVector r_lnorm(r_n);

Environment e = Environment::global_env();
std::vector<int> r_seed = e[".Random.seed"];
int base_seed = r_seed[r_seed[1] + 1];

Memory<real> Output(*device, r_n);

Kernel rlnorm_kernel(*device, r_n, "lnorm_rng", Output, base_seed, r_meanlog, r_sdlog);
rlnorm_kernel.run();

Output.read_from_device();
for(int i = 0; i < r_n; ++i) r_lnorm[i] = Output[i];

Function f("runif"); f(1);

return r_lnorm;
