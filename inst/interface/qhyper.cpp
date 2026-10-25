// Rcpp function body
NumericVector r_p   = as<NumericVector>(p);
int r_m             = as<int>(m);
int r_n             = as<int>(n);
int r_k             = as<int>(k);
int r_count         = r_p.size();

IntegerVector r_qhyper(r_count);
Memory<real> Input(*device, r_count);
Memory<int> Output(*device, r_count);

for(int i = 0; i < r_count; ++i) Input[i] = r_p[i];
Input.write_to_device();

Kernel qhyper_kernel(*device, r_count, "hyper_q", Output, Input, r_m, r_n, r_k);
qhyper_kernel.run();

Output.read_from_device();
for(int i = 0; i < r_count; ++i) r_qhyper[i] = Output[i];

return r_qhyper;
