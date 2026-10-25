// Rcpp function body
NumericVector r_q   = as<NumericVector>(q);
real r_meanlog      = as<real>(meanlog);
real r_sdlog        = as<real>(sdlog);
int r_n             = r_q.size();

NumericVector r_plnorm(r_n);
Memory<real> Input(*device, r_n);
Memory<real> Output(*device, r_n);

for(int i = 0; i < r_n; ++i) Input[i] = r_q[i];
Input.write_to_device();

Kernel plnorm_kernel(*device, r_n, "lnorm_cdf", Output, Input, r_meanlog, r_sdlog);
plnorm_kernel.run();

Output.read_from_device();
for(int i = 0; i < r_n; ++i) r_plnorm[i] = Output[i];

return r_plnorm;
