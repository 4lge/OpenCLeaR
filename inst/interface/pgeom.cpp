// Rcpp function body
NumericVector r_q   = as<NumericVector>(q);
real r_prob         = as<real>(prob);
int r_n             = r_q.size();

NumericVector r_pgeom(r_n);
Memory<real> Input(*device, r_n);
Memory<real> Output(*device, r_n);

for(int i = 0; i < r_n; ++i) Input[i] = r_q[i];
Input.write_to_device();

Kernel pgeom_kernel(*device, r_n, "geom_cdf", Output, Input, r_prob);
pgeom_kernel.run();

Output.read_from_device();
for(int i = 0; i < r_n; ++i) r_pgeom[i] = Output[i];

return r_pgeom;
