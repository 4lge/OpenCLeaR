// Rcpp function body
NumericVector r_x   = as<NumericVector>(x);
real r_shape1       = as<real>(shape1);
real r_shape2       = as<real>(shape2);
int r_n             = r_x.size();

NumericVector r_dbeta(r_n);
Memory<real> Input(*device, r_n);
Memory<real> Output(*device, r_n);

for(int i = 0; i < r_n; ++i) Input[i] = r_x[i];
Input.write_to_device();

Kernel dbeta_kernel(*device, r_n, "beta_pdf", Output, Input, r_shape1, r_shape2);
dbeta_kernel.run();

Output.read_from_device();
for(int i = 0; i < r_n; ++i) r_dbeta[i] = Output[i];

return r_dbeta;
