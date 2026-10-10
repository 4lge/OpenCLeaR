 __kernel void idw_kernel(__global const real_t* x0, __global const real_t* y0, __global real_t* z0,
                          __global const real_t* x, __global const real_t* y, __global const real_t* z,
                          const int n0, const int n, const real_t p) {
     int i = get_global_id(0);
     if (i >= n0) return;
     real_t wsum = 0, num = 0;
     for (int j = 0; j < n; j++) {
         real_t d = sqrt((x0[i]-x[j])*(x0[i]-x[j]) + (y0[i]-y[j])*(y0[i]-y[j]));
         if (d < (real_t)1e-9) { z0[i] = z[j]; return; }
         real_t w = (real_t)1 / pow(d, p);
         wsum += w; num += w * z[j];
     }
     z0[i] = num / wsum;
 }
