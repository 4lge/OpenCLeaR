// Rcpp function body
NumericVector r_p   = as<NumericVector>(p);
int r_df            = as<int>(df);
int r_n             = r_p.size();

NumericVector r_qt(r_n);
Memory<real> Input(*device, r_n);
Memory<real> Output(*device, r_n);

for(int i = 0; i < r_n; ++i) Input[i] = r_p[i];
Input.write_to_device();

Kernel qt_kernel(*device, r_n, "t_q", Output, Input, r_df);
qt_kernel.run();

Output.read_from_device();
for(int i = 0; i < r_n; ++i) r_qt[i] = Output[i];

return r_qt;
