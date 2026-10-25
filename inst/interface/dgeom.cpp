// Rcpp function body
NumericVector r_x   = as<NumericVector>(x);
real r_prob         = as<real>(prob);
int r_n             = r_x.size();

NumericVector r_dgeom(r_n);
Memory<real> Input(*device, r_n);
Memory<real> Output(*device, r_n);

for(int i = 0; i < r_n; ++i) Input[i] = r_x[i];
Input.write_to_device();

Kernel dgeom_kernel(*device, r_n, "geom_pdf", Output, Input, r_prob);
dgeom_kernel.run();

Output.read_from_device();
for(int i = 0; i < r_n; ++i) r_dgeom[i] = Output[i];

return r_dgeom;
