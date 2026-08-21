#include "kernel.hpp" // note: unbalanced round brackets () are not allowed and string literals can't be arbitrarily long, so periodically interrupt with )+R(




string opencl_c_container() {
  string OpenCL_C = R( // ########################## begin of OpenCL C code ####################
                       )
    // Uniform random number generator (Mersenne Twister)
    +R(
#define INIT_MT(mt) (\
  uint mt[624];\
  int idx = 624;\
  mt[0] = *seed + get_global_id(0);\
  for (int i = 1; i < 624; ++i) {\
    mt[i] = (181243 * (mt[i - 1] ^ (mt[i - 1] >> 30)) + i);\
  }\
)
       inline uint mt_rand(__private uint* state, __private int* idx, __private uint* mt) {
         if (*idx >= 624) {
           // Twist the state array
           for (int i = 0; i < 624; ++i) {
             uint temp = mt[i] ^ (mt[(i + 1) % 624] >> 1);
             temp ^= (temp >> 1) ^ ((temp & 1) ? 0x8EB8B000 : 0);
             mt[i] = mt[(i + 397) % 624] ^ temp;
           }
           *idx = 0;
         }
         uint x = mt[*idx];
         x ^= (x >> 11);
         x ^= (x << 7) & 0x9D2C5680;
         x ^= (x << 15) & 0xEFC60000;
         x ^= (x >> 18);
         (*idx)++;
         return x;
       }

       // Mersenne Twister scaled to [0,1]
       inline real_t mt_rand_01(__private uint* state, __private int* idx, __private uint* mt) {
         return (real_t)mt_rand(&mt[0], &idx[0], mt) / 4294967295.0f;
       }
       )
    // PDFs and CDFs
    +R(

       // Normal Distribution (PDF)
       inline real_t normal_pdf(real_t x, real_t mu, real_t sigma) {
         if (sigma <= 0) return 0.0f;
         real_t z = (x - mu) / sigma;
         return (1.0f / (sigma * sqrt(2 * M_PI))) * exp(-0.5f * z * z);
       }

       // Normal CDF Approximation (using erf approximation)
       inline real_t normal_cdf(real_t x, real_t mu, real_t sigma) {
         if (sigma <= 0) return 0.0f;
         real_t z = (x - mu) / sigma;
         real_t t = 1.0 / (1.0 + 0.5f * fabs(z));
         real_t erf_approx = 1.0 - t * exp(-z * z - 1.26523 * t * (t - 1.0 + 0.045 * t));
         return 0.5 * (1.0f + sign(z) * erf_approx);
       }

       )
    // RNG functions
    +R(
       // uniform distribution
       inline real_t runif(__private real_t lower, __private real_t upper,
                    __private int* idx, __private uint* mt) {
         return lower + (upper-lower)*mt_rand_01(&mt[0], &idx[0], mt);
       }

       // normal distribution
       inline real_t rnorm(__private real_t mu, __private real_t sigma,
                    __private int* idx, __private uint* mt) {
         if(get_global_id(0) % 2 ==0)
           return mu + sigma * sqrt(-2 * log(mt_rand_01(&mt[0], &idx[0], mt))) *
             cos(2 * 3.14159265359 * mt_rand_01(&mt[0], &idx[0], mt));
         else
           return mu + sigma * sqrt(-2 * log(mt_rand_01(&mt[0], &idx[0], mt))) *
             cos(2 * 3.14159265359 * mt_rand_01(&mt[0], &idx[0], mt));
       }

       )
    // RNG kernels
    +R(
       // all kernels moved to cl files
       );
  return OpenCL_C;
} // ####################### end of OpenCL C code #####################
