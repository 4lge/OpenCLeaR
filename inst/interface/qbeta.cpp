// Rcpp function body
NumericVector r_p   = as<NumericVector>(p);
real r_shape1       = as<real>(shape1);
real r_shape2       = as<real>(shape2);
int r_n             = r_p.size();

NumericVector r_qbeta(r_n);
Memory<real> Input(*device, r_n);
Memory<real> Output(*device, r_n);

for(int i = 0; i < r_n; ++i) Input[i] = r_p[i];
Input.write_to_device();

Kernel qbeta_kernel(*device, r_n, "beta_q", Output, Input, r_shape1, r_shape2);
qbeta_kernel.run();

Output.read_from_device();
for(int i = 0; i < r_n; ++i) r_qbeta[i] = Output[i];

return r_qbeta;
