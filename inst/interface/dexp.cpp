// Rcpp function body
NumericVector r_x   = as<NumericVector>(x);
real r_rate         = as<real>(rate);
int r_n             = r_x.size();

NumericVector r_dexp(r_n);
Memory<real> Input(*device, r_n);
Memory<real> Output(*device, r_n);

for(int i = 0; i < r_n; ++i) Input[i] = r_x[i];
Input.write_to_device();

Kernel dexp_kernel(*device, r_n, "exp_pdf", Output, Input, r_rate);
dexp_kernel.run();

Output.read_from_device();
for(int i = 0; i < r_n; ++i) r_dexp[i] = Output[i];

return r_dexp;
