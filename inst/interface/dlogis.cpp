// Rcpp function body
NumericVector r_x   = as<NumericVector>(x);
real r_location     = as<real>(location);
real r_scale        = as<real>(scale);
int r_n             = r_x.size();

NumericVector r_dlogis(r_n);
Memory<real> Input(*device, r_n);
Memory<real> Output(*device, r_n);

for(int i = 0; i < r_n; ++i) Input[i] = r_x[i];
Input.write_to_device();

Kernel dlogis_kernel(*device, r_n, "logis_pdf", Output, Input, r_location, r_scale);
dlogis_kernel.run();

Output.read_from_device();
for(int i = 0; i < r_n; ++i) r_dlogis[i] = Output[i];

return r_dlogis;
