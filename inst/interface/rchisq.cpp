// Rcpp function body
int r_n             = as<int>(n);
int r_df           = as<int>(df);

NumericVector r_chisq(r_n);

Environment e = Environment::global_env();
std::vector<int> r_seed = e[".Random.seed"];
int base_seed = r_seed[r_seed[1] + 1];

Memory<real> Output(*device, r_n);

Kernel rchisq_kernel(*device, r_n, "chisq_rng", Output, base_seed, r_df);
rchisq_kernel.run();

Output.read_from_device();
for(int i = 0; i < r_n; ++i) r_chisq[i] = Output[i];

Function f("runif"); f(1);

return r_chisq;
