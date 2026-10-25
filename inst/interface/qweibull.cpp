// Rcpp function body
NumericVector r_p   = as<NumericVector>(p);
real r_shape        = as<real>(shape);
real r_scale        = as<real>(scale);
int r_n             = r_p.size();

NumericVector r_qweibull(r_n);
Memory<real> Input(*device, r_n);
Memory<real> Output(*device, r_n);

for(int i = 0; i < r_n; ++i) Input[i] = r_p[i];
Input.write_to_device();

Kernel qweibull_kernel(*device, r_n, "weibull_q", Output, Input, r_shape, r_scale);
qweibull_kernel.run();

Output.read_from_device();
for(int i = 0; i < r_n; ++i) r_qweibull[i] = Output[i];

return r_qweibull;
