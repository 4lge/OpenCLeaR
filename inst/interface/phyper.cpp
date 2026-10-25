// Rcpp function body
NumericVector r_q   = as<NumericVector>(q);
int r_m             = as<int>(m);
int r_n             = as<int>(n);
int r_k             = as<int>(k);
int r_count         = r_q.size();

NumericVector r_phyper(r_count);
Memory<real> Input(*device, r_count);
Memory<real> Output(*device, r_count);

for(int i = 0; i < r_count; ++i) Input[i] = r_q[i];
Input.write_to_device();

Kernel phyper_kernel(*device, r_count, "hyper_cdf", Output, Input, r_m, r_n, r_k);
phyper_kernel.run();

Output.read_from_device();
for(int i = 0; i < r_count; ++i) r_phyper[i] = Output[i];

return r_phyper;
