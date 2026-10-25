// Rcpp function body
NumericVector r_q   = as<NumericVector>(q);
real r_lambda       = as<real>(lambda);
int r_n             = r_q.size();

NumericVector r_ppois(r_n);
Memory<real> Input(*device, r_n);
Memory<real> Output(*device, r_n);

for(int i = 0; i < r_n; ++i) Input[i] = r_q[i];
Input.write_to_device();

Kernel ppois_kernel(*device, r_n, "pois_cdf", Output, Input, r_lambda);
ppois_kernel.run();

Output.read_from_device();
for(int i = 0; i < r_n; ++i) r_ppois[i] = Output[i];

return r_ppois;
