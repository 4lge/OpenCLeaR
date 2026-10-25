// Rcpp function body
NumericVector r_q   = as<NumericVector>(q);
real r_rate         = as<real>(rate);
int r_n             = r_q.size();

NumericVector r_pexp(r_n);
Memory<real> Input(*device, r_n);
Memory<real> Output(*device, r_n);

for(int i = 0; i < r_n; ++i) Input[i] = r_q[i];
Input.write_to_device();

Kernel pexp_kernel(*device, r_n, "exp_cdf", Output, Input, r_rate);
pexp_kernel.run();

Output.read_from_device();
for(int i = 0; i < r_n; ++i) r_pexp[i] = Output[i];

return r_pexp;
