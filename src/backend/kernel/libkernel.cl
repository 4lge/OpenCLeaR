// 🛡️ DYNAMISCHE STRATEGISCHE ARCHITEKTUR-SCHRÄNKEN
#if defined(cl_khr_fp64) || defined(cl_amd_fp64)
    #define GPGPU_EPSILON 1e-16
    #define GPGPU_SAFE_MAX 1e-300
#else
    #define GPGPU_EPSILON 1e-6f
    #define GPGPU_SAFE_MAX 1e-37f
#endif
// use: (X.Xf * GPGPU_EPSILON)

#define INIT_MT(mt) (\
  uint mt[624];\
  int idx = 624;\
  mt[0] = *seed + get_global_id(0);\
  for (int i = 1; i < 624; ++i) {\
    mt[i] = (181243 * (mt[i - 1] ^ (mt[i - 1] >> 30)) + i);\
  }\
)
       static inline uint mt_rand(__private uint* state, __private int* idx, __private uint* mt) {
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
       static inline real_t mt_rand_01(__private uint* state, __private int* idx, __private uint* mt) {
         return (real_t)mt_rand(&mt[0], &idx[0], mt) / 4294967295;
       }

       // Normal Distribution (PDF)
       static inline real_t normal_pdf(real_t x, real_t mu, real_t sigma) {
         if (sigma <= 0) return 0;
         real_t z = (x - mu) / sigma;
         return (1 / (sigma * sqrt(2 * M_PI))) * exp(-0.5f * z * z);
       }

       // Normal CDF Approximation (using erf approximation)
       static inline real_t normal_cdf(real_t x, real_t mu, real_t sigma) {
         if (sigma <= 0) return 0;
         real_t z = (x - mu) / sigma;
         real_t t = 1 / (1 + 0.5f * fabs(z));
         real_t erf_approx = 1 - t * exp(-z * z - 1.26523f * t * (t - 1 + 0.045f * t));
         return 0.5f * (1 + sign(z) * erf_approx);
       }


       // Exponential PDF
       static inline real_t exponential_pdf(real_t x, real_t lambda) {
         if (lambda <= 0 || x < 0) return 0;
         return lambda * exp(-lambda * x);
       }

       // Exponential CDF
       static inline real_t exponential_cdf(real_t x, real_t lambda) {
         if (lambda <=0 || x < 0) return 0;
         return 1 - exp(-lambda * x);
       }

       // Chi-Squared PDF
       static inline real_t chi_squared_pdf(real_t x, real_t k) {
         if (k <= 0 || x < 0) return 0;
         real_t log_pdf = (k/2.0 - 1) * log(x) - x/2.0 - lgamma(k/2.0) - (k/2.0) * log(2);
         return exp(log_pdf);
       }

       // Chi-Squared CDF
       static inline real_t chi_squared_cdf(real_t x, real_t k) {
         if (k <= 0 || x < 0) return 0;
         return 1 - exp(-x/2.0) * pow(x/2.0, k/2.0) / (tgamma(k/2.0) * pow(2, k/2.0));
       }

       // t-Distribution PDF
       static inline real_t student_t_pdf(real_t x, real_t nu) {
         if (nu <= 0) return 0;
         real_t log_pdf = lgamma((nu + 1) / 2) - lgamma(nu / 2) - 0.5f * log(nu * M_PI);
         log_pdf -= ((nu + 1) / 2) * log(1 + x * x / nu);
         return exp(log_pdf);
       }

       // t-Distribution CDF (approximation via beta function)
       static inline real_t student_t_cdf(real_t x, real_t nu) {
         if (nu <= 0) return 0;
         real_t t = x / sqrt(nu + x * x);
         real_t beta = 0.5f * (1 + t) * pow(1 - t * t, nu / 2);
         return (x < 0) ? beta : 1 - beta;
       }


       // Gamma PDF (Numerisch stabil im Log-Raum)
       static inline real_t gamma_pdf(real_t x, real_t shape_k, real_t scale_theta) {
         if (shape_k <= 0 || scale_theta <= 0 || x < 0) return 0;
         real_t log_pdf = (shape_k - 1) * log(x) - x / scale_theta - lgamma(shape_k) - shape_k * log(scale_theta);
         return exp(log_pdf);
       }

       // Gamma CDF (Numerisch stabil via lgamma)
       static inline real_t gamma_cdf(real_t x, real_t shape_k, real_t scale_theta) {
         if (shape_k <= 0 || scale_theta <= 0 || x < 0) return 0;
         real_t sum = 0;
         for (int n = 0; n < 100; ++n) { 
           // 🎯 Nutzen lgamma statt dem nicht existierenden tgamma!
           real_t log_term = (shape_k + n) * log(x / scale_theta) - lgamma(shape_k + n + 1);
           sum += exp(log_term);
         }
         return sum; // bzw. die entsprechende mathematische Approximation Ihres Series-Expansions
       }
        // Inverse Gamma PDF (Numerisch stabil berechnet im Log-Raum via lgamma)
    static inline real_t invgamma_pdf(real_t x, real_t alpha, real_t beta) {
      if (x <= 0 || alpha <= 0 || beta <= 0) return 0;
      real_t log_pdf = alpha * log(beta) - lgamma(alpha) - (alpha + 1) * log(x) - beta / x;
      return exp(log_pdf);
    }

        // 🚀 INVERSE GAMMA CDF: Verknüpft über die Komplementär-Transformation Ihres Gamma-CDFs
        static inline real_t invgamma_cdf(real_t x, real_t alpha, real_t beta) {
          if (x <= (real_t)0 || alpha <= (real_t)0 || beta <= (real_t)0) return (real_t)0;
          return (real_t)1 - gamma_cdf((real_t)1 / x, alpha, beta);
        }
       // Beta PDF
       static inline real_t beta_pdf(real_t x, real_t alpha, real_t beta_param) {
         if (alpha <= 0 || beta_param <= 0 || x < 0 || x > 1) return 0;
         real_t log_pdf = (alpha - 1) * log(x) + (beta_param - 1) * log(1 - x) - lgamma(alpha + beta_param) + lgamma(alpha) + lgamma(beta_param);
         return exp(log_pdf);
       }

       // Beta CDF (approximation via beta function)
       static inline real_t beta_cdf(real_t x, real_t alpha, real_t beta_param) {
         if (alpha <= 0 || beta_param <= 0 || x < 0 || x > 1) return 0;
         real_t sum = 0;
         for (int k = 0; k < 100; ++k) { // Approximate using series expansion
           sum += pow(x, alpha + k) / (alpha + k) * pow(1 - x, beta_param + k) / (beta_param + k);
         }
         return sum;
       }

       // Weibull PDF
       static inline real_t weibull_pdf(real_t x, real_t shape_k, real_t scale_lambda) {
         if (shape_k <= 0 || scale_lambda <= 0 || x < 0) return 0;
         return (shape_k / scale_lambda) * pow(x / scale_lambda, shape_k - 1) * exp(-pow(x / scale_lambda, shape_k));
       }

       // Weibull CDF
       static inline real_t weibull_cdf(real_t x, real_t shape_k, real_t scale_lambda) {
         if (shape_k <= 0 || scale_lambda <= 0 || x < 0) return 0;
         return 1 - exp(-pow(x / scale_lambda, shape_k));
       }


       // hypergeometric
       static inline real_t log_choose(int a, int b) {
         return lgamma((real_t)(a + 1)) - lgamma((real_t)(b + 1)) - lgamma((real_t)(a - b + 1));
       }
       // Compute hypergeometric PMF
       static inline real_t compute_hyper_pmf(int k, int N, int K, int n) {
         return exp(log_choose(K, k) + log_choose(N - K, n - k) - log_choose(N, n));
       }

       // Binomial PDF
       static inline real_t binomial_pdf(int k, int n, real_t p) {
         if (k < 0 || k > n || p < 0 || p > 1) return 0;
         real_t log_pmf = log_choose(n, k) + k * log(p) + (n - k) * log(1 - p);
         return exp(log_pmf);
       }

       // Binomial CDF
       static inline real_t binomial_cdf(int k, int n, real_t p) {
         if (k < 0 || k > n || p < 0 || p > 1) return 0;
         real_t sum = 0;
         for (int i = 0; i <= k; ++i) {
           sum += binomial_pdf(i, n, p);
         }
         return sum;
       }


       // Poisson PDF
       static inline real_t poisson_pdf(int k, real_t lambda) {
         if (k < 0 || lambda <= 0) return 0;
         real_t log_pmf = -lambda + k * log(lambda) - lgamma(k + 1);
         return exp(log_pmf);
       }

       // Poisson CDF
       static inline real_t poisson_cdf(int k, real_t lambda) {
         if (k < 0 || lambda <= 0) return 0;
         real_t sum = 0;
         for (int i = 0; i <= k; ++i) {
           sum += poisson_pdf(i, lambda);
         }
         return sum;
       }
       // Geometric PDF
       static inline real_t geometric_pdf(int k, real_t p) {
         if (k < 0 || p <= 0 || p > 1) return 0;
         return p * pow(1 - p, k);
       }

       // Geometric CDF
       static inline real_t geometric_cdf(int k, real_t p) {
         if (k < 0 || p <= 0 || p > 1) return 0;
         return 1 - pow(1 - p, k + 1);
       }


       // Negative Binomial PDF
       static inline real_t neg_binomial_pdf(int k, int r, real_t p) {
         if (k < 0 || r <= 0 || p <= 0 || p > 1) return 0;
         real_t log_pmf = log_choose(k + r - 1, k) + r * log(p) + k * log(1 - p);
         return exp(log_pmf);
       }

       // Negative Binomial CDF
       static inline real_t neg_binomial_cdf(int k, int r, real_t p) {
         if (k < 0 || r <= 0 || p <= 0 || p > 1) return 0;
         real_t sum = 0;
         for (int i = 0; i <= k; ++i) {
           sum += neg_binomial_pdf(i, r, p);
         }
         return sum;
       }

       // uniform distribution
       static inline real_t runif(__private real_t lower, __private real_t upper,
                    __private int* idx, __private uint* mt) {
         return lower + (upper-lower)*mt_rand_01(&mt[0], &idx[0], mt);
       }

       // exponential distribution
       static inline real_t rexp(__private real_t rate,
                   __private int* idx, __private uint* mt) {
         return 1.0/rate * (-log(mt_rand_01(&mt[0], &idx[0], mt)));
       }
       // normal distribution
       static inline real_t rnorm(__private real_t mu, __private real_t sigma,
                    __private int* idx, __private uint* mt) {
         if(get_global_id(0) % 2 == 0)
           return mu + sigma * sqrt(-2 * log(mt_rand_01(&mt[0], &idx[0], mt))) *
             cos((real_t)2 * (real_t)M_PI * mt_rand_01(&mt[0], &idx[0], mt)); // 🎯 Nutzen M_PI und saubere Typ-Casts!
         else
           return mu + sigma * sqrt(-2 * log(mt_rand_01(&mt[0], &idx[0], mt))) *
             cos((real_t)2 * (real_t)M_PI * mt_rand_01(&mt[0], &idx[0], mt));
       }

       // t distribution
       static inline real_t rt(__private int nu,
                 __private int* idx, __private uint* mt) {
         real_t V = nu * (-log(mt_rand_01(&mt[0], &idx[0], mt)));
         return sqrt(-2.0 * log(mt_rand_01(&mt[0], &idx[0], mt))) *
           cos((real_t)2 * (real_t)M_PI * mt_rand_01(&mt[0], &idx[0], mt)) * sqrt(nu / V); // 🎯 Nutzen M_PI!
       }

       // chisquared distribution
       static inline real_t rchisq(__private int nu,
                     __private int* idx, __private uint* mt) {
         return nu * (-log(mt_rand_01(&mt[0], &idx[0], mt)));
       }


       // gamma distribution
       static inline real_t rgamma(__private real_t shape, __private real_t scale,
                     __private int* idx, __private uint* mt) {
         real_t ret = -log(mt_rand_01(&mt[0], &idx[0], mt)) * scale * shape;
         return ret;
       }

       //  inverse gamma
       static inline real_t rinvgamma(__private real_t alpha,__private real_t beta,__private int* idx,__private  uint* mt) {
         real_t gamma_val = rgamma(alpha, beta, idx, mt);
         if (gamma_val <= (real_t)0) return (real_t)1e10; // Schutz vor Division durch 0
         return (real_t)1 / gamma_val;
       }
       // beta
       static inline real_t rbeta(__private real_t alpha, __private real_t beta,
                    __private int* idx, __private uint* mt) {
         real_t gamma1 = alpha * (-log(mt_rand_01(&mt[0], &idx[0], mt)));
         real_t gamma2 = beta * (-log(mt_rand_01(&mt[0], &idx[0], mt)));
         return gamma1 / (gamma1 + gamma2);
       }

       // weibull
       static inline real_t rweibull(__private real_t lambda, __private real_t k,
                       __private int* idx, __private uint* mt) {
         return lambda * pow(-log(mt_rand_01(&mt[0], &idx[0], mt)), 1 / k);
       }


       // binomial distribution (shape theta, rate 1/k)
       static inline uint rbinom(__private int size, __private real_t prob,
                   __private int* idx, __private uint* mt) {
         uint count = 0;
         for (int i = 0; i < size; ++i) {
           count += (mt_rand_01(&mt[0], &idx[0], mt) < prob); // Requires multiple uniforms
         }
         return count;
       }

       // geometric
       static inline uint rgeom(__private real_t prob,
                  __private int* idx, __private uint* mt){
         return floor(log(mt_rand_01(&mt[0], &idx[0], mt)) / log(1 - prob));
       }

       // negative binomial
       static inline uint rnbinom(__private int size, __private real_t prob,
                    __private int* idx, __private uint* mt){
         uint sum = 0;
         for (int i = 0; i < size; ++i) {
           sum += floor(log(mt_rand_01(&mt[0], &idx[0], mt)) / log(1 - prob)); // Requires multiple uniforms
         }
         return sum;
       }

       // poisson
       static inline uint rpois(__private real_t lambda,
                  __private int* idx, __private uint* mt){
         uint k = 0;
         real_t sum_exponentials = 0;
         while (sum_exponentials <= 1) { // Sum exponentials until exceed 1
           sum_exponentials += -log(mt_rand_01(&mt[0], &idx[0], mt)) * lambda;
           k++;
         }
         return k-1;
       }

       // hypergeometric
       static inline uint rhyperg(__private int white, __private int black, __private int size,
                    __private int* idx, __private uint* mt){
         int N = white + black, K = white, n = size;
         // Ratio-of-Uniforms parameters
         real_t h = 1; // Adjust based on PMF scaling

         // Generate candidate k using u2 (assuming max_k = min(n, K))
         int max_k = min(n, K);
         int min_k = max(0, n - (N - K));

         // Compute PMF bounds and ratio-of-uniforms condition
         real_t max_pmf = 0;
         for (int k = min_k; k <= max_k; ++k) {
           // Compute log combinations to avoid overflow
           real_t pmf = compute_hyper_pmf(k, N, K, n);
           max_pmf = max(max_pmf, pmf);
         }

         while(true){
           real_t u1 = mt_rand_01(&mt[0], &idx[0], mt);
           real_t u2 = mt_rand_01(&mt[0], &idx[0], mt);
           uint k_candidate = min_k + (int)(u2 * (max_k - min_k + 1));
           real_t pmf = compute_hyper_pmf(k_candidate, N, K, n);
           // Ratio check
           if (u1 <= pmf * h / max_pmf) {
             if(k_candidate<n)
               return ++k_candidate; // Accepted k value
           }
         }
       }
