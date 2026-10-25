// Rcpp function body
NumericVector r_x   = as<NumericVector>(x);
int r_df1          = as<int>(df1);
int r_df2          = as<int>(df2);
int r_n             = r_x.size();

NumericVector r_df(r_n);
Memory<real> Input(*device, r_n);
Memory<real> Output(*device, r_n);

for(int i = 0; i < r_n; ++i) Input[i] = r_x[i];
Input.write_to_device();

Kernel df_kernel(*device, r_n, "f_pdf", Output, Input, r_df1, r_df2);
df_kernel.run();

Output.read_from_device();
for(int i = 0; i < r_n; ++i) r_df[i] = Output[i];

return r_df;
