// Rcpp function body
NumericVector r_p   = as<NumericVector>(p);
int r_df           = as<int>(df);
int r_n             = r_p.size();

NumericVector r_qchisq(r_n);
Memory<real> Input(*device, r_n);
Memory<real> Output(*device, r_n);

for(int i = 0; i < r_n; ++i) Input[i] = r_p[i];
Input.write_to_device();

Kernel qchisq_kernel(*device, r_n, "chisq_q", Output, Input, r_df);
qchisq_kernel.run();

Output.read_from_device();
for(int i = 0; i < r_n; ++i) r_qchisq[i] = Output[i];

return r_qchisq;
