// Rcpp function body
int r_n             = as<int>(n);
real r_shape        = as<real>(shape);
real r_rate         = as<real>(rate);

NumericVector r_gamma(r_n);

Environment e = Environment::global_env();
std::vector<int> r_seed = e[".Random.seed"];
int base_seed = r_seed[r_seed[1] + 1];

Memory<real> Output(*device, r_n);

Kernel rgamma_kernel(*device, r_n, "gamma_rng", Output, base_seed, r_shape, r_rate);
rgamma_kernel.run();

Output.read_from_device();
for(int i = 0; i < r_n; ++i) r_gamma[i] = Output[i];

Function f("runif"); f(1);

return r_gamma;
