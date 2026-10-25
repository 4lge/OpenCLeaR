// Rcpp function body
NumericVector r_p   = as<NumericVector>(p);
int r_size          = as<int>(size);
real r_prob         = as<real>(prob);
int r_n             = r_p.size();

IntegerVector r_qnbinom(r_n);
Memory<real> Input(*device, r_n);
Memory<int> Output(*device, r_n);

for(int i = 0; i < r_n; ++i) Input[i] = r_p[i];
Input.write_to_device();

Kernel qnbinom_kernel(*device, r_n, "nbinom_q", Output, Input, r_size, r_prob);
qnbinom_kernel.run();

Output.read_from_device();
for(int i = 0; i < r_n; ++i) r_qnbinom[i] = Output[i];

return r_qnbinom;
