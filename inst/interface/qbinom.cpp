// Rcpp function body
NumericVector r_p   = as<NumericVector>(p);
int r_size         = as<int>(size);
real r_prob         = as<real>(prob);
int r_n             = r_p.size();

IntegerVector r_qbinom(r_n);
Memory<real> Input(*device, r_n);
Memory<int> Output(*device, r_n);

for(int i = 0; i < r_n; ++i) Input[i] = r_p[i];
Input.write_to_device();

Kernel qbinom_kernel(*device, r_n, "binom_q", Output, Input, r_size, r_prob);
qbinom_kernel.run();

Output.read_from_device();
for(int i = 0; i < r_n; ++i) r_qbinom[i] = Output[i];

return r_qbinom;
