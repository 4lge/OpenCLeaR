// Rcpp function body
NumericVector r_p   = as<NumericVector>(p);
real r_location     = as<real>(location);
real r_scale        = as<real>(scale);
int r_n             = r_p.size();

NumericVector r_qcauchy(r_n);
Memory<real> Input(*device, r_n);
Memory<real> Output(*device, r_n);

for(int i = 0; i < r_n; ++i) Input[i] = r_p[i];
Input.write_to_device();

Kernel qcauchy_kernel(*device, r_n, "cauchy_q", Output, Input, r_location, r_scale);
qcauchy_kernel.run();

Output.read_from_device();
for(int i = 0; i < r_n; ++i) r_qcauchy[i] = Output[i];

return r_qcauchy;
