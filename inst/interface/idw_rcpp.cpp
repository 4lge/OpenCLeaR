NumericVector x0(r_x0);
NumericVector y0(r_y0);
NumericVector x(r_x);
NumericVector y(r_y);
NumericVector z(r_z);

int n0 = x0.size(); 
int n = x.size(); 
NumericVector r_z0(n0);

Memory<real_t> gpu_x0(*device, n0); 
Memory<real_t> gpu_y0(*device, n0); 
Memory<real_t> gpu_z0(*device, n0);
Memory<real_t> gpu_x(*device, n); 
Memory<real_t> gpu_y(*device, n); 
Memory<real_t> gpu_z(*device, n);

// Jetzt klappt der Zugriff über [] absolut makellos und performant!
for(int i=0; i<n0; ++i) { gpu_x0[i] = x0[i]; gpu_y0[i] = y0[i]; }
for(int j=0; j<n; ++j)  { gpu_x[j] = x[j]; gpu_y[j] = y[j]; gpu_z[j] = z[j]; }

gpu_x0.write_to_device(); gpu_y0.write_to_device();
gpu_x.write_to_device(); gpu_y.write_to_device(); gpu_z.write_to_device();

Kernel k(*device, n0, "idw_kernel", gpu_x0, gpu_y0, gpu_z0, gpu_x, gpu_y, gpu_z, n0, n, as<real_t>(p));
k.run(); 
gpu_z0.read_from_device();

for(int i=0; i<n0; ++i) r_z0[i] = gpu_z0[i];
return r_z0;
