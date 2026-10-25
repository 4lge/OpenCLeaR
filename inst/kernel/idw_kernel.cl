 __kernel void idw_kernel(__global const real* x0, __global const real* y0, __global real* z0,
                          __global const real* x, __global const real* y, __global const real* z,
                          const int n0, const int n, const real p) {
     int i = get_global_id(0);
     if (i >= n0) return;
     real wsum = 0, num = 0;
     for (int j = 0; j < n; j++) {
         real d = sqrt((x0[i]-x[j])*(x0[i]-x[j]) + (y0[i]-y[j])*(y0[i]-y[j]));
         if (d < GPGPU_EPSILON) { z0[i] = z[j]; return; }
         real w = (real)1 / pow(d, p);
         wsum += w; num += w * z[j];
     }
     z0[i] = num / wsum;
 }
