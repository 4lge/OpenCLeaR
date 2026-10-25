// Rcpp function body
int r_n             = as<int>(n);
int r_df1          = as<int>(df1);
int r_df2          = as<int>(df2);

NumericVector r_f(r_n);

Environment e = Environment::global_env();
std::vector<int> r_seed = e[".Random.seed"];
int base_seed = r_seed[r_seed[1] + 1];

Memory<real> Output(*device, r_n);

Kernel rf_kernel(*device, r_n, "f_rng", Output, base_seed, r_df1, r_df2);
rf_kernel.run();

Output.read_from_device();
for(int i = 0; i < r_n; ++i) r_f[i] = Output[i];

Function f("runif"); f(1);

return r_f;
