// Rcpp function body
NumericVector r_p   = as<NumericVector>(p);
real r_shape        = as<real>(shape);
real r_rate         = as<real>(rate);
int r_n             = r_p.size();

NumericVector r_qgamma(r_n);
Memory<real> Input(*device, r_n);
Memory<real> Output(*device, r_n);

for(int i = 0; i < r_n; ++i) Input[i] = r_p[i];
Input.write_to_device();

Kernel qgamma_kernel(*device, r_n, "gamma_q", Output, Input, r_shape, r_rate);
qgamma_kernel.run();

Output.read_from_device();
for(int i = 0; i < r_n; ++i) r_qgamma[i] = Output[i];

return r_qgamma;
