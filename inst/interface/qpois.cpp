// Rcpp function body
NumericVector r_p   = as<NumericVector>(p);
real r_lambda       = as<real>(lambda);
int r_n             = r_p.size();

IntegerVector r_qpois(r_n);
Memory<real> Input(*device, r_n);
Memory<int> Output(*device, r_n);

for(int i = 0; i < r_n; ++i) Input[i] = r_p[i];
Input.write_to_device();

Kernel qpois_kernel(*device, r_n, "pois_q", Output, Input, r_lambda);
qpois_kernel.run();

Output.read_from_device();
for(int i = 0; i < r_n; ++i) r_qpois[i] = Output[i];

return r_qpois;
