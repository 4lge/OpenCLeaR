// Rcpp function body
int r_n             = as<int>(n);
real r_shape1       = as<real>(shape1);
real r_shape2       = as<real>(shape2);

NumericVector r_beta(r_n);

Environment e = Environment::global_env();
std::vector<int> r_seed = e[".Random.seed"];
int base_seed = r_seed[r_seed[1] + 1];

Memory<real> Output(*device, r_n);

Kernel rbeta_kernel(*device, r_n, "beta_rng", Output, base_seed, r_shape1, r_shape2);
rbeta_kernel.run();

Output.read_from_device();
for(int i = 0; i < r_n; ++i) r_beta[i] = Output[i];

Function f("runif"); f(1);

return r_beta;
