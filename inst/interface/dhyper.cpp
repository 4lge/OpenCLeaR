// Rcpp function body
NumericVector r_x   = as<NumericVector>(x);
real r_m             = as<real>(m);
real r_n             = as<real>(n);
real r_k             = as<real>(k);
int r_count         = r_x.size();

NumericVector r_dhyper(r_count);
Memory<real> Input(*device, r_count);
Memory<real> Output(*device, r_count);

for(int i = 0; i < r_count; ++i) Input[i] = r_x[i];
Input.write_to_device();

Kernel dhyper_kernel(*device, r_count, "hyper_pdf", Output, Input, r_m, r_n, r_k);
dhyper_kernel.run();

Output.read_from_device();
for(int i = 0; i < r_count; ++i) r_dhyper[i] = Output[i];

return r_dhyper;
