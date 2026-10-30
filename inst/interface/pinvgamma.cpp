NumericVector r_q     = as<NumericVector>(q);
real r_shape        = as<real>(shape);
real r_rate         = as<real>(rate);
int r_n             = r_q.size();

NumericVector r_out(r_n);
Memory<real> GetQ(*device, r_n);
Memory<real> Output(*device, r_n);

for(int i = 0; i < r_n; ++i) GetQ[i] = r_q[i];
GetQ.write_to_device();

Kernel pinvgamma_kernel(*device, r_n, "pinvgamma_kernel", Output, GetQ, r_shape, r_rate, r_n);
pinvgamma_kernel.run();

Output.read_from_device();
for(int i = 0; i < r_n; ++i) r_out[i] = Output[i];
return r_out;
