// Rcpp function body
NumericVector r_q   = as<NumericVector>(q);
int r_df           = as<int>(df);
int r_n             = r_q.size();

NumericVector r_pt(r_n);
Memory<real> Input(*device, r_n);
Memory<real> Output(*device, r_n);

for(int i = 0; i < r_n; ++i) Input[i] = r_q[i];
Input.write_to_device();

Kernel pt_kernel(*device, r_n, "t_cdf", Output, Input, r_df);
pt_kernel.run();

Output.read_from_device();
for(int i = 0; i < r_n; ++i) r_pt[i] = Output[i];

return r_pt;
