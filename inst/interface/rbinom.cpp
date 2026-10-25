// Rcpp function body
int r_n             = as<int>(n);
int r_size         = as<int>(size);
real r_prob         = as<real>(prob);

IntegerVector r_binom(r_n);

Environment e = Environment::global_env();
std::vector<int> r_seed = e[".Random.seed"];
int base_seed = r_seed[r_seed[1] + 1];

Memory<int> Output(*device, r_n);

Kernel rbinom_kernel(*device, r_n, "binom_rng", Output, base_seed, r_size, r_prob);
rbinom_kernel.run();

Output.read_from_device();
for(int i = 0; i < r_n; ++i) r_binom[i] = Output[i];

Function f("runif"); f(1);

return r_binom;
