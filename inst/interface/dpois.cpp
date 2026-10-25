// Rcpp function body
NumericVector r_x   = as<NumericVector>(x);
real r_lambda       = as<real>(lambda);
int r_n             = r_x.size();

NumericVector r_dpois(r_n);
Memory<real> Input(*device, r_n);
Memory<real> Output(*device, r_n);

for(int i = 0; i < r_n; ++i) Input[i] = r_x[i];
Input.write_to_device();

Kernel dpois_kernel(*device, r_n, "pois_pdf", Output, Input, r_lambda);
dpois_kernel.run();

Output.read_from_device();
for(int i = 0; i < r_n; ++i) r_dpois[i] = Output[i];

return r_dpois;
