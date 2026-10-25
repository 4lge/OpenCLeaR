// Rcpp function body
NumericVector r_q   = as<NumericVector>(q);
real r_shape        = as<real>(shape);
real r_rate         = as<real>(rate);
int r_n             = r_q.size();

NumericVector r_pgamma(r_n);
Memory<real> Input(*device, r_n);
Memory<real> Output(*device, r_n);

for(int i = 0; i < r_n; ++i) Input[i] = r_q[i];
Input.write_to_device();

Kernel pgamma_kernel(*device, r_n, "gamma_cdf", Output, Input, r_shape, r_rate);
pgamma_kernel.run();

Output.read_from_device();
for(int i = 0; i < r_n; ++i) r_pgamma[i] = Output[i];

return r_pgamma;
