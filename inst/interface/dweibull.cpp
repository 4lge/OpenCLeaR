// Rcpp function body
NumericVector r_x   = as<NumericVector>(x);
real r_shape        = as<real>(shape);
real r_scale        = as<real>(scale);
int r_n             = r_x.size();

NumericVector r_dweibull(r_n);
Memory<real> Input(*device, r_n);
Memory<real> Output(*device, r_n);

for(int i = 0; i < r_n; ++i) Input[i] = r_x[i];
Input.write_to_device();

Kernel dweibull_kernel(*device, r_n, "weibull_pdf", Output, Input, r_shape, r_scale);
dweibull_kernel.run();

Output.read_from_device();
for(int i = 0; i < r_n; ++i) r_dweibull[i] = Output[i];

return r_dweibull;
