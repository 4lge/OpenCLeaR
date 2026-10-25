// Rcpp function body
NumericVector r_x   = as<NumericVector>(x);
int r_df           = as<int>(df);
int r_n             = r_x.size();

NumericVector r_dchisq(r_n);
Memory<real> Input(*device, r_n);
Memory<real> Output(*device, r_n);

for(int i = 0; i < r_n; ++i) Input[i] = r_x[i];
Input.write_to_device();

Kernel dchisq_kernel(*device, r_n, "chisq_pdf", Output, Input, r_df);
dchisq_kernel.run();

Output.read_from_device();
for(int i = 0; i < r_n; ++i) r_dchisq[i] = Output[i];

return r_dchisq;
