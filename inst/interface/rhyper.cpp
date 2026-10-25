// Rcpp function body
int r_count         = as<int>(n);
int r_m             = as<int>(m);
int r_n             = as<int>(n);
int r_k             = as<int>(k);

IntegerVector r_hyper(r_count);

Environment e = Environment::global_env();
std::vector<int> r_seed = e[".Random.seed"];
int base_seed = r_seed[r_seed[1] + 1];

Memory<int> Output(*device, r_count);

Kernel rhyper_kernel(*device, r_count, "hyper_rng", Output, base_seed, r_m, r_n, r_k);
rhyper_kernel.run();

Output.read_from_device();
for(int i = 0; i < r_count; ++i) r_hyper[i] = Output[i];

Function f("runif"); f(1);

return r_hyper;
