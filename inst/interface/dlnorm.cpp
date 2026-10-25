// Rcpp function body
NumericVector r_x   = as<NumericVector>(x);
real r_meanlog      = as<real>(meanlog);
real r_sdlog        = as<real>(sdlog);
int r_n             = r_x.size();

NumericVector r_dlnorm(r_n);
Memory<real> Input(*device, r_n);
Memory<real> Output(*device, r_n);

for(int i = 0; i < r_n; ++i) Input[i] = r_x[i];
Input.write_to_device();

Kernel dlnorm_kernel(*device, r_n, "lnorm_pdf", Output, Input, r_meanlog, r_sdlog);
dlnorm_kernel.run();

Output.read_from_device();
for(int i = 0; i < r_n; ++i) r_dlnorm[i] = Output[i];

return r_dlnorm;
