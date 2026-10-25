// Rcpp function body
int r_n             = as<int>(n);
real r_shape        = as<real>(shape);
real r_scale        = as<real>(scale);

NumericVector r_weibull(r_n);

Environment e = Environment::global_env();
std::vector<int> r_seed = e[".Random.seed"];
int base_seed = r_seed[r_seed[1] + 1];

Memory<real> Output(*device, r_n);

Kernel rweibull_kernel(*device, r_n, "weibull_rng", Output, base_seed, r_shape, r_scale);
rweibull_kernel.run();

Output.read_from_device();
for(int i = 0; i < r_n; ++i) r_weibull[i] = Output[i];

Function f("runif"); f(1);

return r_weibull;
