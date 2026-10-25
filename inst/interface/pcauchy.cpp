// Rcpp function body
NumericVector r_q   = as<NumericVector>(q);
real r_location     = as<real>(location);
real r_scale        = as<real>(scale);
int r_n             = r_q.size();

NumericVector r_pcauchy(r_n);
Memory<real> Input(*device, r_n);
Memory<real> Output(*device, r_n);

for(int i = 0; i < r_n; ++i) Input[i] = r_q[i];
Input.write_to_device();

Kernel pcauchy_kernel(*device, r_n, "cauchy_cdf", Output, Input, r_location, r_scale);
pcauchy_kernel.run();

Output.read_from_device();
for(int i = 0; i < r_n; ++i) r_pcauchy[i] = Output[i];

return r_pcauchy;
