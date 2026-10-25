// Rcpp function body
NumericVector r_x   = as<NumericVector>(x);
real r_size         = as<real>(size);
real r_prob         = as<real>(prob);
int r_n             = r_x.size();

NumericVector r_dbinom(r_n);
Memory<real> Input(*device, r_n);
Memory<real> Output(*device, r_n);

for(int i = 0; i < r_n; ++i) Input[i] = r_x[i];
Input.write_to_device();

Kernel dbinom_kernel(*device, r_n, "binom_pdf", Output, Input, r_size, r_prob);
dbinom_kernel.run();

Output.read_from_device();
for(int i = 0; i < r_n; ++i) r_dbinom[i] = Output[i];

return r_dbinom;
