NumericVector r_x     = as<NumericVector>(x);
real r_shape        = as<real>(shape);
real r_rate         = as<real>(rate);
int r_n             = r_x.size();

NumericVector r_out(r_n);
Memory<real> GetX(*device, r_n);
Memory<real> Output(*device, r_n);

for(int i = 0; i < r_n; ++i) GetX[i] = r_x[i];
GetX.write_to_device();

Kernel dinvgamma_kernel(*device, r_n, "dinvgamma_kernel", Output, GetX, r_shape, r_rate, r_n);
dinvgamma_kernel.run();

Output.read_from_device();
for(int i = 0; i < r_n; ++i) r_out[i] = Output[i];
return r_out;
