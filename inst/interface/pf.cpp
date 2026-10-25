// Rcpp function body
NumericVector r_q   = as<NumericVector>(q);
int r_df1          = as<int>(df1);
int r_df2          = as<int>(df2);
int r_n             = r_q.size();

NumericVector r_pf(r_n);
Memory<real> Input(*device, r_n);
Memory<real> Output(*device, r_n);

for(int i = 0; i < r_n; ++i) Input[i] = r_q[i];
Input.write_to_device();

Kernel pf_kernel(*device, r_n, "f_cdf", Output, Input, r_df1, r_df2);
pf_kernel.run();

Output.read_from_device();
for(int i = 0; i < r_n; ++i) r_pf[i] = Output[i];

return r_pf;
