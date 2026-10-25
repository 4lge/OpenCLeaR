// Rcpp function body for Gaussian Process Covariance Engine

// 1. Read input, compare exactly to signature in oclFunction call:
NumericVector r_x(X);
int N_dim = as<int>(N);
int total_matrix_size = N_dim * N_dim;

// 2. Allocate output variables (flattened N x N vector)
NumericVector out_K(total_matrix_size);

// 3. Create OpenCL variables using your native Memory layers
Memory<real> GpuX(*device, N_dim);
Memory<real> GpuK(*device, total_matrix_size);

// 4. Fill OpenCL host-buffer components
for(int i = 0; i < N_dim; ++i) {
    GpuX[i] = (real)r_x[i];
}

// 5. Transfer input coordinates from host to VRAM
GpuX.write_to_device();

// 6. Map constants and scalars safely to real
real length_scale_typed = as<real>(length_scale);
real sigma_f_sq_typed   = as<real>(sigma_f_sq);
real sigma_n_sq_typed   = as<real>(sigma_n_sq);

// 7. Define local workgroup size (0 triggers the driver's automatic selection)
uint local_workgroup_size = 0;

// 8. Create the 2D Kernel object using the native (N, M, workgroup_size) template!
// GpuK ist das Ausgabeargument, das im Kernel als 'K' deklariert ist.
Kernel gp_kernel(*device, 
                 (ulong)N_dim, 
                 (ulong)N_dim, 
                 local_workgroup_size, 
                 "gp_covariance_kernel", 
                 GpuX, GpuK, N_dim, length_scale_typed, sigma_f_sq_typed, sigma_n_sq_typed);

// 9. 🔥 Kernel execution call
gp_kernel.run();

// 10. Transfer computed covariance matrix back from device to host
GpuK.read_from_device();

// 11. Stream OpenCL memory back into the Rcpp output vector
for(int i = 0; i < total_matrix_size; ++i) {
    out_K[i] = GpuK[i];
}

// 12. Return results as a flat vector ready for matrix conversion in R
return out_K;
