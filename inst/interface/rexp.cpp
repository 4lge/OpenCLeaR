// Rcpp function body
int r_n             = as<int>(n);
real r_rate         = as<real>(rate);

NumericVector r_exp(r_n);

Environment e = Environment::global_env();
std::vector<int> r_seed = e[".Random.seed"];
int base_seed = r_seed[r_seed[1] + 1];

Memory<real> Output(*device, r_n);

Kernel rexp_kernel(*device, r_n, "exp_rng", Output, base_seed, r_rate);
rexp_kernel.run();

Output.read_from_device();
for(int i = 0; i < r_n; ++i) r_exp[i] = Output[i];

Function f("runif"); f(1);

return r_exp;
