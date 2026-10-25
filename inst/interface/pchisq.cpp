// Rcpp function body
NumericVector r_q   = as<NumericVector>(q);
int r_df           = as<int>(df);
int r_n             = r_q.size();

NumericVector r_pchisq(r_n);
Memory<real> Input(*device, r_n);
Memory<real> Output(*device, r_n);

for(int i = 0; i < r_n; ++i) Input[i] = r_q[i];
Input.write_to_device();

Kernel pchisq_kernel(*device, r_n, "chisq_cdf", Output, Input, r_df);
pchisq_kernel.run();

Output.read_from_device();
for(int i = 0; i < r_n; ++i) r_pchisq[i] = Output[i];

return r_pchisq;
