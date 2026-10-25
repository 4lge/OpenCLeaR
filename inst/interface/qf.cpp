// Rcpp function body
NumericVector r_p   = as<NumericVector>(p);
int r_df1          = as<int>(df1);
int r_df2          = as<int>(df2);
int r_n             = r_p.size();

NumericVector r_qf(r_n);
Memory<real> Input(*device, r_n);
Memory<real> Output(*device, r_n);

for(int i = 0; i < r_n; ++i) Input[i] = r_p[i];
Input.write_to_device();

Kernel qf_kernel(*device, r_n, "f_q", Output, Input, r_df1, r_df2);
qf_kernel.run();

Output.read_from_device();
for(int i = 0; i < r_n; ++i) r_qf[i] = Output[i];

return r_qf;
