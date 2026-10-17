// Rcpp function body

// 1. Inputs einlesen
int r_n          = as<int>(n);
real_t r_shape1  = as<real_t>(shape1);
real_t r_shape2  = as<real_t>(shape2);

// Allocate output variables
NumericVector r_beta(r_n);

// 2. Seed aus der R-Session holen
Environment e = Environment::global_env();
std::vector<int> r_seed = e[".Random.seed"];
int base_seed = r_seed[r_seed[1] + 1];

// 3. Nur noch den Output-Buffer auf der GPU reservieren
Memory<real_t> Output(*device, r_n);

// 4. Kernel erstellen: base_seed wird als skalarer int direkt übergeben!
Kernel rbeta(*device, r_n, "beta_rng", Output, base_seed, r_shape1, r_shape2);

// 🔥 Kernel auf der GPU ausführen
rbeta.run();

// Transfer von GPU zu Host
Output.read_from_device();

// In Rcpp-Vektor schreiben
for(int i=0; i<r_n; ++i) {
  r_beta[i] = Output[i];
}

// Seed-Update in R erzwingen
Function f("runif"); f(1);

return r_beta;
