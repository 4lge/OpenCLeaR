// Rcpp function body
NumericVector r_p   = as<NumericVector>(p);
real r_meanlog      = as<real>(meanlog);
real r_sdlog        = as<real>(sdlog);
int r_n             = r_p.size();

NumericVector r_qlnorm(r_n);
Memory<real> Input(*device, r_n);
Memory<real> Output(*device, r_n);

for(int i = 0; i < r_n; ++i) Input[i] = r_p[i];
Input.write_to_device();

Kernel qlnorm_kernel(*device, r_n, "lnorm_q", Output, Input, r_meanlog, r_sdlog);
qlnorm_kernel.run();

Output.read_from_device();
for(int i = 0; i < r_n; ++i) r_qlnorm[i] = Output[i];

return r_qlnorm;
