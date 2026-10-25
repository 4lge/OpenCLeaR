// Rcpp function body
NumericVector r_q   = as<NumericVector>(q);
real r_shape1       = as<real>(shape1);
real r_shape2       = as<real>(shape2);
int r_n             = r_q.size();

NumericVector r_pbeta(r_n);
Memory<real> Input(*device, r_n);
Memory<real> Output(*device, r_n);

for(int i = 0; i < r_n; ++i) Input[i] = r_q[i];
Input.write_to_device();

Kernel pbeta_kernel(*device, r_n, "beta_cdf", Output, Input, r_shape1, r_shape2);
pbeta_kernel.run();

Output.read_from_device();
for(int i = 0; i < r_n; ++i) r_pbeta[i] = Output[i];

return r_pbeta;
