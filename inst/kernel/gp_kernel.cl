__kernel void gp_covariance_kernel(
    __global const real_t* GpuX,
    __global real_t* GpuK,
    const int N,
    const real_t length_scale,
    const real_t sigma_f_sq,
    const real_t sigma_n_sq)
{
    // Map 2D Global IDs to Matrix Coordinates (Row i, Column j)
    int i = get_global_id(0); 
    int j = get_global_id(1); 

    // Boundary protection
    if (i >= N || j >= N) return;

    // Calculate Squared Euclidean Distance
    real_t diff = GpuX[i] - GpuX[j];
    real_t dist_sq = diff * diff;
    
    real_t ls_sq = length_scale * length_scale;
    if (ls_sq < (real_t)1e-12) {
        ls_sq = (real_t)1e-12; // force safe value
    }
    // Core RBF / Squared Exponential Equation
    real_t cov_val = sigma_f_sq * exp((real_t)-0.5 * dist_sq / ls_sq;

    // Inject Nugget (Noise) along the main diagonal for numerical stability
    if (i == j) {
        cov_val += sigma_n_sq;
    }

    // Write back to row-major flattened 1D Global Memory Buffer
    GpuK[i * N + j] = cov_val;
}
