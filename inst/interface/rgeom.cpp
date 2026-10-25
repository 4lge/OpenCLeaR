// Rcpp function body
int r_n             = as<int>(n);
real r_prob         = as<real>(prob);

IntegerVector r_geom(r_n);

Environment e = Environment::global_env();
std::vector<int> r_seed = e[".Random.seed"];
int base_seed = r_seed[r_seed[1] + 1];

Memory<int> Output(*device, r_n);

Kernel rgeom_kernel(*device, r_n, "geom_rng", Output, base_seed, r_prob);
rgeom_kernel.run();

Output.read_from_device();
for(int i = 0; i < r_n; ++i) r_geom[i] = Output[i];

Function f("runif"); f(1);

return r_geom;
