// Rcpp function body
NumericVector r_p   = as<NumericVector>(p);
real r_location     = as<real>(location);
real r_scale        = as<real>(scale);
int r_n             = r_p.size();

NumericVector r_qlogis(r_n);
Memory<real> Input(*device, r_n);
Memory<real> Output(*device, r_n);

for(int i = 0; i < r_n; ++i) Input[i] = r_p[i];
Input.write_to_device();

Kernel qlogis_kernel(*device, r_n, "logis_q", Output, Input, r_location, r_scale);
qlogis_kernel.run();

Output.read_from_device();
for(int i = 0; i < r_n; ++i) r_qlogis[i] = Output[i];

return r_qlogis;
