NumericVector r_p     = as<NumericVector>(p);
real r_shape        = as<real>(shape);
real r_rate         = as<real>(rate);
int r_n             = r_p.size();

NumericVector r_out(r_n);
Memory<real> GetP(*device, r_n);
Memory<real> Output(*device, r_n);

for(int i = 0; i < r_n; ++i) GetP[i] = r_p[i];
GetP.write_to_device();

Kernel qinvgamma_kernel(*device, r_n, "qinvgamma_kernel", Output, GetP, r_shape, r_rate, r_n);
qinvgamma_kernel.run();

Output.read_from_device();
for(int i = 0; i < r_n; ++i) r_out[i] = Output[i];
return r_out;
