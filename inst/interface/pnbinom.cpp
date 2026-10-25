// Rcpp function body
NumericVector r_q   = as<NumericVector>(q);
int r_size          = as<int>(size);
real r_prob         = as<real>(prob);
int r_n             = r_q.size();

NumericVector r_pnbinom(r_n);
Memory<real> Input(*device, r_n);
Memory<real> Output(*device, r_n);

for(int i = 0; i < r_n; ++i) Input[i] = r_q[i];
Input.write_to_device();

Kernel pnbinom_kernel(*device, r_n, "nbinom_cdf", Output, Input, r_size, r_prob);
pnbinom_kernel.run();

Output.read_from_device();
for(int i = 0; i < r_n; ++i) r_pnbinom[i] = Output[i];

return r_pnbinom;
