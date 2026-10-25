// Rcpp function body
NumericVector r_p   = as<NumericVector>(p);
real r_rate         = as<real>(rate);
int r_n             = r_p.size();

NumericVector r_qexp(r_n);
Memory<real> Input(*device, r_n);
Memory<real> Output(*device, r_n);

for(int i = 0; i < r_n; ++i) Input[i] = r_p[i];
Input.write_to_device();

Kernel qexp_kernel(*device, r_n, "exp_q", Output, Input, r_rate);
qexp_kernel.run();

Output.read_from_device();
for(int i = 0; i < r_n; ++i) r_qexp[i] = Output[i];

return r_qexp;
