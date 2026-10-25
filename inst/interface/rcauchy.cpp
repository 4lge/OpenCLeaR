// Rcpp function body
int r_n             = as<int>(n);
real r_location     = as<real>(location);
real r_scale        = as<real>(scale);

NumericVector r_cauchy(r_n);

Environment e = Environment::global_env();
std::vector<int> r_seed = e[".Random.seed"];
int base_seed = r_seed[r_seed[1] + 1];

Memory<real> Output(*device, r_n);

Kernel rcauchy_kernel(*device, r_n, "cauchy_rng", Output, base_seed, r_location, r_scale);
rcauchy_kernel.run();

Output.read_from_device();
for(int i = 0; i < r_n; ++i) r_cauchy[i] = Output[i];

Function f("runif"); f(1);

return r_cauchy;
