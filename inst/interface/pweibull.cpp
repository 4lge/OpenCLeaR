// Rcpp function body
NumericVector r_q   = as<NumericVector>(q);
real r_shape        = as<real>(shape);
real r_scale        = as<real>(scale);
int r_n             = r_q.size();

NumericVector r_pweibull(r_n);
Memory<real> Input(*device, r_n);
Memory<real> Output(*device, r_n);

for(int i = 0; i < r_n; ++i) Input[i] = r_q[i];
Input.write_to_device();

Kernel pweibull_kernel(*device, r_n, "weibull_cdf", Output, Input, r_shape, r_scale);
pweibull_kernel.run();

Output.read_from_device();
for(int i = 0; i < r_n; ++i) r_pweibull[i] = Output[i];

return r_pweibull;
