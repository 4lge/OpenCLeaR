// Rcpp function body
NumericVector r_x   = as<NumericVector>(x);
real r_shape        = as<real>(shape);
real r_rate         = as<real>(rate);
int r_n             = r_x.size();

NumericVector r_dgamma(r_n);
Memory<real> Input(*device, r_n);
Memory<real> Output(*device, r_n);

for(int i = 0; i < r_n; ++i) Input[i] = r_x[i];
Input.write_to_device();

Kernel dgamma_kernel(*device, r_n, "gamma_pdf", Output, Input, r_shape, r_rate);
dgamma_kernel.run();

Output.read_from_device();
for(int i = 0; i < r_n; ++i) r_dgamma[i] = Output[i];

return r_dgamma;
