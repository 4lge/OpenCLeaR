// -*- c -*-

//  define seveeal constants regarding float/double differences
#if defined(cl_khr_fp64) || defined(cl_amd_fp64)
#define GPGPU_EPSILON 1e-16
#define GPGPU_SAFE_MAX 1e-300
#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif
#ifndef M_E
#define M_E  2.71828182845904523536
#endif
#else
#define GPGPU_EPSILON 1e-6f
#define GPGPU_SAFE_MAX 1e-37f
#ifndef M_PI
#define M_PI 3.1415926536f
#endif
#ifndef M_E
#define M_E  2.7182818285f
#endif
#endif
#if defined(cl_khr_fp64) || defined(cl_amd_fp64)
  #define REAL_MIN DBL_MIN
#else
  #define REAL_MIN FLT_MIN
#endif
// oerloads for int arguments to functions working on real  arguments
__attribute__((overloadable)) static inline real lgamma(int x) { return lgamma((real)x); }
__attribute__((overloadable)) static inline real log(int x)    { return log((real)x); }
__attribute__((overloadable)) static inline real sqrt(int x)   { return sqrt((real)x); }
__attribute__((overloadable)) static inline real exp(int x)    { return exp((real)x); }
__attribute__((overloadable)) static inline real sin(int x)    { return sin((real)x); }
__attribute__((overloadable)) static inline real cos(int x)    { return cos((real)x); }
__attribute__((overloadable)) static inline real tan(int x)    { return tan((real)x); }
// LIST NEEDS TO BE CONTINUED ...

// RNG initialization and seed setting
#define INIT_MT(seed) \
  uint mt[624]; \
  int idx = 624; \
  mt[0] = (seed) + get_global_id(0); \
  for (int i = 1; i < 624; ++i) { \
    mt[i] = (181243 * (mt[i - 1] ^ (mt[i - 1] >> 30)) + i); \
  }


// =========================================================================
// CENTRAL FORWARD DECLARATIONS (Verhindert Reihenfolge-Fehler)
// =========================================================================

// --- Mersenne Twister RNG ---
static inline uint mt_rand(__private uint* state, __private int* idx, __private uint* mt);
static inline real mt_rand_01(__private int* idx, __private uint* mt);

// --- Normal Distribution ---
static inline real dnorm(real x, real mean, real sd);
static inline real pnorm(real x, real mean, real sd);
static inline real qnorm(real p, real mu, real sigma);
static inline real rnorm_internal(__private real mu, __private real sigma, __private int* idx, __private uint* mt);

// --- Uniform Distribution ---
static inline real dunif(real x, real min, real max);
static inline real punif(real q, real min, real max);
static inline real qunif(real p, real min, real max);
static inline real runif_internal(real min, real max, __private int* idx, __private uint* mt);

// --- Poisson Distribution ---
static inline real dpois(real x, real lambda);
static inline real ppois(real q, real lambda);
static inline int qpois(real p, real lambda);
static inline int rpois_internal(real lambda, __private int* idx, __private uint* mt);

// --- Binomial Distribution ---
static inline real dbinom(real x, int n, real p);
static inline real pbinom(real q, int n, real p);
static inline int qbinom(real prob, int n, real p);
static inline int rbinom_internal(int n, real p, __private int* idx, __private uint* mt);

// --- Exponential Distribution ---
static inline real dexp(real x, real rate);
static inline real pexp(real q, real rate);
static inline real qexp(real p, real rate);
static inline real rexp_internal(real rate, __private int* idx, __private uint* mt);

// --- Geometric Distribution ---
static inline real dgeom(real x, real prob);
static inline real pgeom(real q, real prob);
static inline int qgeom(real p, real prob);
static inline int rgeom_internal(real prob, __private int* idx, __private uint* mt);

// --- Negative Binomial Distribution ---
static inline real dnbinom(real x, int size, real prob);
static inline real pnbinom(real q, int size, real prob);
static inline int qnbinom(real p, int size, real prob);
static inline int rnbinom_internal(int size, real prob, __private int* idx, __private uint* mt);

// --- Hypergeometric Distribution ---
static inline real dhyper(real x, int m, int n, int k);
static inline real phyper(real q, int m, int n, int k);
static inline int qhyper(real p, int m, int n, int k);
static inline int rhyper_internal(int m, int n, int k, __private int* idx, __private uint* mt);

// --- Gamma Distribution ---
static inline real dgamma(real x, real shape, real rate);
static inline real pgamma(real q, real shape, real rate);
static inline real qgamma(real p, real shape, real rate);
static inline real rgamma_internal(real shape, real rate, __private int* idx, __private uint* mt);

// --- Weibull Distribution ---
static inline real dweibull(real x, real shape, real scale);
static inline real pweibull(real q, real shape, real scale);
static inline real qweibull(real p, real shape, real scale);
static inline real rweibull_internal(real shape, real scale, __private int* idx, __private uint* mt);

// --- Chi-Squared Distribution ---
static inline real dchisq(real x, int df);
static inline real pchisq(real q, int df);
static inline real qchisq(real p, int df);
static inline real rchisq_internal(int df, __private int* idx, __private uint* mt);

// --- Student-t Distribution ---
static inline real dt(real x, int df);
static inline real pt(real q, int df);
static inline real qt(real p, int df);
static inline real rt_internal(int df, __private int* idx, __private uint* mt);

// --- Inverse Gamma Distribution ---
static inline real dinvgamma(const real x, const real shape, const real rate);
static inline real pinvgamma(const real x, const real shape, const real rate);
static inline real qinvgamma(const real p, const real shape, const real rate);
static inline real rinvgamma_internal(const real shape, const real rate, __private int* idx, __private uint* mt);


// --- Beta Distribution ---
static inline real core_incomplete_beta(real x, real a, real b); 
static inline real dbeta(real x, real shape1, real shape2);
static inline real pbeta(real q, real shape1, real shape2);
static inline real qbeta(real p, real shape1, real shape2);
static inline real rbeta_internal(real shape1, real shape2, __private int* idx, __private uint* mt);

// --- F Distribution ---
static inline real df(real x, int df1, int df2);
static inline real pf(real q, int df1, int df2);
static inline real qf(real p, int df1, int df2);
static inline real rf_internal(int df1, int df2, __private int* idx, __private uint* mt);

// --- Log-Normal Distribution ---
static inline real dlnorm(real x, real meanlog, real sdlog);
static inline real plnorm(real q, real meanlog, real sdlog);
static inline real qlnorm(real p, real meanlog, real sdlog);
static inline real rlnorm_internal(real meanlog, real sdlog, __private int* idx, __private uint* mt);

// --- Cauchy Distribution ---
static inline real dcauchy(real x, real location, real scale);
static inline real pcauchy(real q, real location, real scale);
static inline real qcauchy(real p, real location, real scale);
static inline real rcauchy_internal(real location, real scale, __private int* idx, __private uint* mt);

// --- Logistic Distribution ---
static inline real dlogis(real x, real location, real scale);
static inline real plogis(real q, real location, real scale);
static inline real qlogis(real p, real location, real scale);
static inline real rlogis_internal(real location, real scale, __private int* idx, __private uint* mt);

// --- Model Fitting Lin-Alg Workspace ---
static inline int core_qr_ls_solve(const real *A_in, const real *b_in, int m, int n, real *x, real *R, real *qty);
static inline int generate_poly_design_matrix_safe(const real *x_data, int m, int degree, real *A_out, real *x_min_out, real *x_scale_out);
static inline int restore_original_coefficients(const real *c_norm, int degree, real x_min, real x_scale, real *a_orig, real *binom_space);
static inline int core_cholesky(const real *Sigma, int m, real *L);
static inline int wls_gls_fit(const real *A_in, const real *b_in, int m, int n, const real *Sigma, const real *weights, real *x_out, real *workspace_A_tilde, real *workspace_b_tilde, real *workspace_L, real *workspace_col, real *workspace_R, real *workspace_qty);
static inline int ls_poly_fit(const real *x_data, const real *y_data, int m, int degree, real *a_out, real *total_workspace);




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
static inline real mt_rand_01(__private int* idx, __private uint* mt) {
  // divide by 4294967295+1 to get into [0,1)
  return (real)mt_rand(&mt[0], &idx[0], mt) / 4294967296.0f;
}


// =========================================================================
// NORMAL DISTRIBUTION 
// =========================================================================

// Normal Distribution (PDF)
static inline real dnorm(real x, real mean, real sd) {
  if (sd <= 0.0f) return 0.0f;
  real z = (x - mean) / sd;
  return (1.0f / (sd * sqrt(2.0f * M_PI))) * exp(-0.5f * z * z);
}

// Normal CDF (using erfc)
static inline real pnorm(real x, real mean, real sd) {
  if (sd <= (real)0.0f) return (real)0.0f;
  real z = (x - mean) / sd;
  
  // Use the high-precision erfc function built into the OpenCL-C standard.
  return (real)0.5f * erfc(-z / sqrt((real)2.0f));
}

// Normal Quantile
static inline real qnorm(real p, real mu, real sigma) {
  if (sigma <= (real)0.0f) return (real)0.0f;
  if (p <= (real)0.0f) return -INFINITY;
  if (p >= (real)1.0f) return INFINITY;

  real q, r, t;

  if (p > (real)0.025f && p < (real)0.975f) {
    // 1. central region (flat behaviour)
    q = p - (real)0.5f;
    r = q * q;
    t = q * ((((((((real)-2.5490809287301226727e3f * r + 
                  (real)3.3430585583326954329e4f) * r - 
                 (real)6.7265770927008700105e4f) * r + 
                (real)4.5921953931549871457e4f) * r - 
               (real)1.3731693765509461125e4f) * r + 
              (real)1.9715909503065094404e3f) * r - 
             (real)1.3314166789178437745e2f) * r + 
            (real)3.3871328727963666080e0f) /
         ((((((((real)5.2264952788528545610e3f * r - 
              (real)2.8729085735721942674e4f) * r + 
             (real)3.9307895800092710610e4f) * r - 
            (real)2.1213794301586595851e4f) * r + 
           (real)5.3941960214247511077e3f) * r - 
          (real)6.8718700749205790830e2f) * r + 
         (real)4.2313330701600911252e1f) * r - (real)1.0f);
  } else {
    // 2. border region
    r = (p <= (real)0.025f) ? p : ((real)1.0f - p);
    t = sqrt(-(real)log(r)); 
    
    q = ((((((((real)7.4245853427844152930e-4f * t + 
               (real)2.1384464432927050751e-2f) * t + 
              (real)2.3158182032484056381e-1f) * t + 
             (real)1.2851316852056238754e0f) * t + 
            (real)3.6478483247632046050e0f) * t + 
           (real)5.7694972214606914055e0f) * t + 
          (real)4.6303378461565452959e0f) * t + 
         (real)1.4234371107496835773e0f) /
      ((((((((real)9.1798364847372227220e-3f * t + 
              (real)1.5497255561113713508e-1f) * t + 
             (real)1.1370089758332959491e0f) * t + 
            (real)4.3413143505342411516e0f) * t + 
           (real)8.7508276002690394774e0f) * t + 
          (real)9.1404456299847534446e0f) * t + 
         (real)4.7784653641792713111e0f) * t + (real)1.0f);
         
    if (p <= (real)0.025f) q = -q;
  }

  real x = mu + q * sigma;

  // 3. Newton-Raphson Loop (benefits from erfc use!)
  for (int i = 0; i < 8; ++i) {
    real pdf = dnorm(x, mu, sigma);
    if (isnan(pdf) || isinf(pdf) || pdf <= (real)GPGPU_SAFE_MAX) break;
    
    real diff = pnorm(x, mu, sigma) - p;
    x -= diff / pdf; 
  }

  return x;
}

// RNG
static inline real rnorm_internal(__private real mu, __private real sigma,
                                  __private int* idx, __private uint* mt) {
  // Since 'mt' and 'idx' are already pointers, we pass them DIRECTLY!
  real u1 = mt_rand_01(&idx[0], mt);
  real u2 = mt_rand_01(&idx[0], mt);
  // symmetrically mix both branches based on thread id. 
  if(get_global_id(0) % 2 == 1)
    return mu + sigma * sqrt((real)-2.0f * log(u1)) *
           cos((real)2.0f * (real)M_PI * u2);
  else
    return mu + sigma * sqrt((real)-2.0f * log(u1)) *
           sin((real)2.0f * (real)M_PI * u2); 
}
#define rnorm(mu, sigma) rnorm_internal((mu), (sigma), &idx, mt)


// =========================================================================
// UNIFORM DISTRIBUTION 
// =========================================================================

// Density (PDF)
static inline real dunif(real x, real min, real max) {
  if (x < min || x > max || min >= max) return (real)0.0f;
  return (real)1.0f / (max - min);
}

// Distribution function (CDF)
static inline real punif(real q, real min, real max) {
  if (min >= max || q < min) return (real)0.0f;
  if (q >= max) return (real)1.0f;
  return (q - min) / (max - min);
}

// Quantile function (Inverse CDF)
static inline real qunif(real p, real min, real max) {
  if (p < (real)0.0f || p > (real)1.0f || min >= max) return (real)NAN;
  return min + p * (max - min);
}

// RNG
static inline real runif_internal(real min, real max, __private int* idx, __private uint* mt) {
  if (min >= max) return (real)NAN;
  // mt_rand_01 liefert eine Zahl in [0,1)
  return min + mt_rand_01(idx, mt) * (max - min);
}
#define runif(min, max) runif_internal((min), (max), &idx, mt)


// =========================================================================
// POISSON DISTRIBUTION (Poisson distribution)
// =========================================================================

// Probability function (PDF)
static inline real dpois(real x, real lambda) {
  if (lambda < (real)0.0f || x < (real)0.0f) return (real)0.0f;
  // Note: Internally uses our math.cl helper functions (e.g. lgamma or exp/pow)
  // For discrete values, x should be an integer.
  real k = floor(x);
  if (k != x) return (real)0.0f;
  
  // Alternative use via log scale to avoid overflows: exp(-lambda + k*log(lambda) - lgamma(k + 1))
  return exp(-lambda + k * log(lambda) - lgamma(k + (real)1.0f));
}

// Distribution function (CDF)
static inline real ppois(real q, real lambda) {
  if (lambda < (real)0.0f) return (real)0.0f;
  if (q < (real)0.0f) return (real)0.0f;
  
  // Use the incomplete gamma function (regularized gamma Q or P) if available,
  // or a classic iterative loop for small/medium lambdas:
  real k = floor(q);
  real sum = (real)0.0f;
  for (int i = 0; i <= (int)k; ++i) {
    sum += exp(-lambda + (real)i * log(lambda) - lgamma((real)i + (real)1.0f));
  }
  return sum;
}

// Quantile function (Inverse CDF)
static inline int qpois(real p, real lambda) {
  if (p < (real)0.0f || p > (real)1.0f || lambda < (real)0.0f) return -1;
  if (p == (real)0.0f) return 0;
  
  real term = exp(-lambda);
  real sum = term;
  int k = 0;
  real epsilon =  GPGPU_EPSILON; 

  while (k < 100000) {
    if (sum >= (p - epsilon)) {
      return k;
    }
    k++;
    term *= lambda / (real)k;
    sum += term;
  }
  return k;
}

// Internal RNG function (Knuth method for small lambda, inversion for large lambda)
static inline int rpois_internal(real lambda, __private int* idx, __private uint* mt) {
  if (lambda < (real)0.0f) return (real)NAN;
  
  // Einfache Knuth-Methode für die Simulation
  real L = exp(-lambda);
  int k = 0;
  real p = (real)1.0f;
  
  do {
    k++;
    p *= mt_rand_01(idx, mt);
  } while (p > L && k < 100000);
  
  return k - 1;
}

// The macro hides the MT variables again
#define rpois(lambda) rpois_internal((lambda), &idx, mt)

// =========================================================================
// binomial distribution
// =========================================================================

// Probability function (PDF)
static inline real dbinom(real x, int n, real p) {
  if (p < (real)0.0f || p > (real)1.0f || n < 0) return (real)0.0f;
  int k = floor(x);
  if (k < 0 || k > n || k != x) return (real)0.0f;
  if (p == (real)0.0f) return (k == 0) ? (real)1.0f : (real)0.0f;
  if (p == (real)1.0f) return (k == n) ? (real)1.0f : (real)0.0f;
  
  // n! / (k! * (n-k)!) via lgamma:
  real log_bin_coeff = lgamma(n + (real)1.0f) - (lgamma(k + (real)1.0f) + lgamma(n - k + (real)1.0f));
  return exp(log_bin_coeff + k * log(p) + (n - k) * log((real)1.0f - p));
}

// Distribution function (CDF)
static inline real pbinom(real q, int n, real p) {
  if (p < (real)0.0f || p > (real)1.0f || n < 0) return (real)0.0f;
  if (q < (real)0.0f) return (real)0.0f;
  if (q >= n) return (real)1.0f;
  
  real k_max = floor(q);
  real sum = (real)0.0f;
  for (int i = 0; i <= (int)k_max; ++i) {
    sum += dbinom((real)i, n, p);
  }
  return sum;
}

// Quantile function (Inverse CDF)
static inline int qbinom(real prob, int n, real p) {
  if (prob < (real)0.0f || prob > (real)1.0f || p < (real)0.0f || p > (real)1.0f || n < 0) return (real)NAN;
  if (prob == (real)0.0f) return (real)0.0f;
  if (prob == (real)1.0f) return n;
  
  real sum = (real)0.0f;
  int k = 0;
  while (k <= n) {
    sum += dbinom((real)k, n, p);
    if (sum >= prob) return (real)k;
    k++;
  }
  return n;
}

// Internal RNG function (coin toss method for small n, inversion for large n)
static inline int rbinom_internal(int n, real p, __private int* idx, __private uint* mt) {
  if (p < (real)0.0f || p > (real)1.0f || n < 0) return (real)NAN;
  
  int successes = 0;
  
  // For small to medium n we directly simulate the individual tests (Bernoulli)
  for (int i = 0; i < n; ++i) {
    if (mt_rand_01(idx, mt) <= p) {
      successes++;
    }
  }
  return successes;
}

#define rbinom(size, prob) rbinom_internal((size), (prob), &idx, mt)

// =========================================================================
// exponential distribution
// =========================================================================

// Density function (PDF)
static inline real dexp(real x, real rate) {
  if (rate <= (real)0.0f || x < (real)0.0f) return (real)0.0f;
  return rate * exp(-rate * x);
}

// Distribution function (CDF)
static inline real pexp(real q, real rate) {
  if (rate <= (real)0.0f || q < (real)0.0f) return (real)0.0f;
  return (real)1.0f - exp(-rate * q);
}

// Quantile function (Inverse CDF)
static inline real qexp(real p, real rate) {
  if (p < (real)0.0f || p > (real)1.0f || rate <= (real)0.0f) return (real)NAN;
  if (p == (real)1.0f) return (real)INFINITY;
  return -log((real)1.0f - p) / rate;
}

// Internal RNG function (inversion method)
static inline real rexp_internal(real rate, __private int* idx, __private uint* mt) {
  if (rate <= (real)0.0f) return (real)NAN;
  // Since mt_rand_01 is in [0,1), 1.0 - u is in (0,1], making log() safe against -Inf
  real u = mt_rand_01(idx, mt);
  return -log((real)1.0f - u) / rate;
}

#define rexp(rate) rexp_internal((rate), &idx, mt)

// =========================================================================
// geometric distribution
// =========================================================================

// Probability mass function (PMF)
static inline real dgeom(real x, real prob) {
  if (prob <= (real)0.0f || prob > (real)1.0f || x < (real)0.0f) return (real)0.0f;
  real k = floor(x);
  if (k != x) return (real)0.0f;
  if (prob == (real)1.0f) return (k == (real)0.0f) ? (real)1.0f : (real)0.0f;
  
  return prob * exp(k * log((real)1.0f - prob));
}

// Cumulative distribution function (CDF)
static inline real pgeom(real q, real prob) {
  if (prob <= (real)0.0f || prob > (real)1.0f) return (real)0.0f;
  if (q < (real)0.0f) return (real)0.0f;
  if (prob == (real)1.0f) return (real)1.0f;
  
  real k = floor(q);
  return (real)1.0f - exp((k + (real)1.0f) * log((real)1.0f - prob));
}

// Quantile function (Inverse CDF)
static inline int qgeom(real p, real prob) {
  if (p < (real)0.0f || p > (real)1.0f || prob <= (real)0.0f || prob > (real)1.0f) return -1;
  if (p == (real)0.0f) return 0;
  if (p == (real)1.0f) return 2147483647; // INT_MAX for p = 1
  if (prob == (real)1.0f) return 0;

  // THE ORIGINAL R-CORE ALGORITHM (From src/nmath/qgeom.c):
  // R uses: ceil(log(1 - p) / log(1 - prob) - 1e-7) - 1;
  // The subtracted GPGPU_EPSILON prevents exact integer boundaries 
  // incorrectly rounded up due to GPU bit inaccuracies.
  
  real num = log((real)1.0f - p);
  real denom = log((real)1.0f - prob);
  
  int q = (int)ceil(num / denom - GPGPU_EPSILON) - 1;
  
  return q < 0 ? 0 : q;
}

// Internal RNG function (Inversion method via continuous exponential)
static inline int rgeom_internal(real prob, __private int* idx, __private uint* mt) {
  if (prob <= (real)0.0f || prob > (real)1.0f) return (real)NAN;
  if (prob == (real)1.0f) return (real)0.0f;
  
  real u = mt_rand_01(idx, mt);
  // floor(log(1-u) / log(1-prob)) simulates exactly the number of failures
  return (int)(floor(log((real)1.0f - u) / log((real)1.0f - prob)));
}

// 🎯 The macro hides the MT variables for the kernel call
#define rgeom(prob) rgeom_internal((prob), &idx, mt)


// =========================================================================
// negative binomial distribution
// =========================================================================

// Probability mass function (PMF)
static inline real dnbinom(real x, int size, real prob) {
  if (prob <= (real)0.0f || prob > (real)1.0f || size <= 0 || x < (real)0.0f) return (real)0.0f;
  real k = floor(x);
  if (k != x) return (real)0.0f;
  
  // Gamma(k + size) / (Gamma(k + 1) * Gamma(size)) * prob^size * (1-prob)^k via lgamma
  real log_bin_coeff = lgamma(k + size) - (lgamma(k + (real)1.0f) + lgamma(size));
  return exp(log_bin_coeff + size * log(prob) + k * log((real)1.0f - prob));
}

// Cumulative distribution function (CDF)
static inline real pnbinom(real q, int size, real prob) {
  if (prob <= (real)0.0f || prob > (real)1.0f || size <= 0) return (real)0.0f;
  if (q < (real)0.0f) return (real)0.0f;
  
  real k_max = floor(q);
  real sum = (real)0.0f;
  for (int i = 0; i <= (int)k_max; ++i) {
    sum += dnbinom((real)i, size, prob);
  }
  return sum;
}

// Quantile function (Inverse CDF)
static inline int qnbinom(real p, int size, real prob) {
  if (p < (real)0.0f || p > (real)1.0f || prob <= (real)0.0f || prob > (real)1.0f || size <= 0) return (real)NAN;
  if (p == (real)0.0f) return (real)0.0f;
  if (p == (real)1.0f) return (real)INFINITY;
  
  real sum = (real)0.0f;
  int k = 0;
  while (k < 100000) { // Safety guard against infinite loops
    sum += dnbinom((real)k, size, prob);
    if (sum >= p) return (real)k;
    k++;
  }
  return k;
}

// Internal RNG function (Gamma-Poisson mixture method)
static inline int rnbinom_internal(int size, real prob, __private int* idx, __private uint* mt) {
  if (prob <= (real)0.0f || prob > (real)1.0f || size <= 0) return (real)NAN;
  
  real u = mt_rand_01(idx, mt);
  real sum = (real)0.0f;
  int k = 0;
  while (k < 100000) {
    sum += dnbinom((real)k, size, prob);
    if (sum >= u) return (real)k;
    k++;
  }
  return k;
}

#define rnbinom(size, prob) rnbinom_internal((size), (prob), &idx, mt)

// =========================================================================
// hypergeometric distribution
// =========================================================================

// Probability mass function (PDF)
static inline real dhyper(real x, int m, int n, int k) {
  real x_floor = floor(x);
  if (x_floor != x || x < (real)0.0f || x > m || x > k || (k - x) > n) return (real)0.0f;
  
  // dhyper = [choose(m, x) * choose(n, k - x)] / choose(m + n, k) via lgamma
  real log_c_m_x = lgamma(m + (real)1.0f) - (lgamma(x + (real)1.0f) + lgamma(m - x + (real)1.0f));
  real log_c_n_kx = lgamma(n + (real)1.0f) - (lgamma(k - x + (real)1.0f) + lgamma(n - (k - x) + (real)1.0f));
  real log_c_mn_k = lgamma(m + n + (real)1.0f) - (lgamma(k + (real)1.0f) + lgamma(m + n - k + (real)1.0f));
  
  return exp(log_c_m_x + log_c_n_kx - log_c_mn_k);
}

// Cumulative distribution function (CDF)
static inline real phyper(real q, int m, int n, int k) {
  if (q < (real)0.0f) return (real)0.0f;
  real x_max = floor(q);
  real sum = (real)0.0f;
  int upper_bound = (int)(x_max < m ? (x_max < k ? x_max : k) : (m < k ? m : k));
  
  for (int i = 0; i <= upper_bound; ++i) {
    sum += dhyper((real)i, m, n, k);
  }
  return sum;
}

// Quantile function (Inverse CDF)
static inline int qhyper(real p, int m, int n, int k) {
  if (p < (real)0.0f || p > (real)1.0f) return (real)NAN;
  if (p == (real)0.0f) return (real)0.0f;
  
  real sum = (real)0.0f;
  int upper_bound = (int)(m < k ? m : k);
  for (int i = 0; i <= upper_bound; ++i) {
    sum += dhyper((real)i, m, n, k);
    if (sum >= p) return (real)i;
  }
  return upper_bound;
}

// Internal RNG function (Stochastic simulation of drawing without replacement)
static inline int rhyper_internal(int m, int n, int k, __private int* idx, __private uint* mt) {
  int successes = 0;
  
  for (int i = 0; i < k; ++i) {
    real p = (real)m / (real)(m + n);
    if (mt_rand_01(idx, mt) <= p) {
      successes++;
      m--;
    } else {
      n--;
    }
  }
  return successes;
}

#define rhyper(m, n, k) rhyper_internal((m), (n), (k), &idx, mt)

// =========================================================================
// gamma distribution
// =========================================================================

// Probability Density Function (PDF)
static inline real dgamma(real x, real shape, real rate) {
  if (shape <= (real)0.0f || rate <= (real)0.0f || x < (real)0.0f) return (real)0.0f;
  if (x == (real)0.0f) {
    if (shape < (real)1.0f) return (real)INFINITY;
    if (shape == (real)1.0f) return rate;
    return (real)0.0f;
  }
  // rate^shape * x^(shape-1) * exp(-rate * x) / Gamma(shape) via Log-Skala
  real log_density = shape * log(rate) + (shape - (real)1.0f) * log(x) - (rate * x) - lgamma(shape);
  return exp(log_density);
}

// Cumulative Distribution Function (CDF) via incomplete gamma series or approximation
static inline real pgamma(real q, real shape, real rate) {
  if (shape <= (real)0.0f || rate <= (real)0.0f) return (real)0.0f;
  if (q <= (real)0.0f) return (real)0.0f;
  
  // Uses the scaled value x = q * rate
  real x = q * rate;
  
  // Series expansion for the regulated lower gamma (P(a, x))
  real sum = (real)1.0f / shape;
  real term = sum;
  for (int i = 1; i < 100; ++i) {
    term *= x / (shape + (real)i);
    sum += term;
    if (term < sum * (real)1e-7f) break; // Präzisions-Guard
  }
  return sum * exp(-x + shape * log(x) - lgamma(shape));
}

// Quantile Function (Inverse CDF) via numerical Newton-Raphson refinement
static inline real qgamma(real p, real shape, real rate) {
  if (p < (real)0.0f || p > (real)1.0f || shape <= (real)0.0f || rate <= (real)0.0f) return (real)NAN;
  if (p == (real)0.0f) return (real)0.0f;
  if (p == (real)1.0f) return (real)INFINITY;
  
  // First rough estimate (Wilson-Hilferty transformation)
  real d = (real)1.0f / ((real)9.0f * shape);
  real v = (real)1.0f - d + qnorm(p, (real)0.0f, (real)1.0f) * sqrt(d);
  real guess = shape * v * v * v / rate;
  if (guess < (real)0.0f) guess = (real)1e-5f;
  
  // Newton-Raphson refinement loop
  for (int i = 0; i < 10; ++i) {
    real error = pgamma(guess, shape, rate) - p;
    if (fabs(error) < (real)1e-6f) break;
    real deriv = dgamma(guess, shape, rate);
    if (deriv == (real)0.0f) break;
    guess -= error / deriv;
    if (guess <= (real)0.0f) guess = (real)1e-5f;
  }
  return guess;
}

// RNG
static inline real rgamma_internal(real shape, real rate, __private int* idx, __private uint* mt) {
  if (shape <= (real)0.0f || rate <= (real)0.0f) return (real)NAN;
  
  real d_shape = shape;
  real scale = (real)1.0f / rate;
  real adjustment = (real)1.0f;

  //  recursion-free Ahrens-Dieter step for shape < 1
  if (d_shape < (real)1.0f) {
    real u = mt_rand_01(idx, mt);
    if (u <= (real)0.0f) u = (real)GPGPU_SAFE_MAX;
    adjustment = pow(u, (real)1.0f / d_shape);
    d_shape += (real)1.0f; // Switches to the Marsaglia-Tsang base
  }
  
  real d = d_shape - (real)0.3333333f;
  real c = (real)1.0f / sqrt((real)9.0f * d);
  int safety_guard = 0;

  while (1) {
    if (safety_guard++ > 500) {
      return d * scale * adjustment; 
    }
    
    real u1 = mt_rand_01(idx, mt);
    real u2 = mt_rand_01(idx, mt);
    if (u1 <= (real)0.0f) u1 = (real)GPGPU_SAFE_MAX;
    
    real z = sqrt((real)-2.0f * log(u1)) * cos((real)2.0f * (real)M_PI * u2);
    
    // Guard against NaNs from Box-Muller
    if (isnan(z) || isinf(z)) continue;

    real v = (real)1.0f + c * z;
    if (v <= (real)0.0f || isnan(v) || isinf(v)) continue;
    
    v = v * v * v;
    real u = mt_rand_01(idx, mt);
    if (u <= (real)0.0f) u = (real)GPGPU_SAFE_MAX;
    
    if (u < (real)1.0f - (real)0.0331f * z * z * z * z) {
      return d * v * scale * adjustment;
    }
    if (log(u) < (real)0.5f * z * z + d * ((real)1.0f - v + log(v))) {
      return d * v * scale * adjustment;
    }
  }
}

#define rgamma(shape, rate) rgamma_internal((shape), (rate), &idx, mt)

// =========================================================================
// weibull distribution
// =========================================================================

// Probability Density Function (PDF)
static inline real dweibull(real x, real shape, real scale) {
  if (shape <= (real)0.0f || scale <= (real)0.0f || x < (real)0.0f) return (real)0.0f;
  if (x == (real)0.0f) {
    if (shape < (real)1.0f) return (real)INFINITY;
    if (shape == (real)1.0f) return (real)1.0f / scale;
    return (real)0.0f;
  }
  real fraction = x / scale;
  return (shape / scale) * pow(fraction, shape - (real)1.0f) * exp(-pow(fraction, shape));
}

// Cumulative Distribution Function (CDF)
static inline real pweibull(real q, real shape, real scale) {
  if (shape <= (real)0.0f || scale <= (real)0.0f) return (real)0.0f;
  if (q <= (real)0.0f) return (real)0.0f;
  return (real)1.0f - exp(-pow(q / scale, shape));
}

// Quantile Function (Inverse CDF)
static inline real qweibull(real p, real shape, real scale) {
  if (p < (real)0.0f || p > (real)1.0f || shape <= (real)0.0f || scale <= (real)0.0f) return (real)NAN;
  if (p == (real)0.0f) return (real)0.0f;
  if (p == (real)1.0f) return (real)INFINITY;
  return scale * pow(-log((real)1.0f - p), (real)1.0f / shape);
}

// Internal RNG function (Inversion method)
static inline real rweibull_internal(real shape, real scale, __private int* idx, __private uint* mt) {
  if (shape <= (real)0.0f || scale <= (real)0.0f) return (real)NAN;
  real u = mt_rand_01(idx, mt);
  // Since u is in [0,1), 1.0 - u is in (0,1], absolutely safe for the logarithm
  return scale * pow(-log((real)1.0f - u), (real)1.0f / shape);
}

// 🎯 The macro hides the MT variables for the kernel call
#define rweibull(shape, scale) rweibull_internal((shape), (scale), &idx, mt)

// =========================================================================
// chi-squared distribution
// =========================================================================

// Probability Density Function (PDF)
static inline real dchisq(real x, int df) {
  if (df <= 0) return (real)0.0f;
  // Chi-squared(df) is identical to Gamma(shape = df/2, rate = 0.5)
  return dgamma(x, df * (real)0.5f, (real)0.5f);
}

// Cumulative Distribution Function (CDF)
static inline real pchisq(real q, int df) {
  if (df <= 0) return (real)0.0f;
  return pgamma(q, df * (real)0.5f, (real)0.5f);
}

// Quantile Function (Inverse CDF)
static inline real qchisq(real p, int df) {
  if (p < (real)0.0f || p > (real)1.0f || df <= 0) return (real)NAN;
  return qgamma(p, df * (real)0.5f, (real)0.5f);
}

// Internal RNG function (via Gamma transformation)
static inline real rchisq_internal(int df, __private int* idx, __private uint* mt) {
  if (df <= 0) return (real)NAN;
  return rgamma_internal(df * (real)0.5f, (real)0.5f, idx, mt);
}

#define rchisq(df) rchisq_internal((df), &idx, mt)



// =========================================================================
// inverse gamma
// =========================================================================

// Density (PDF): Calculated in stable log space via lgamma
static inline real dinvgamma(const real x, const real shape, const real rate) {
  if (x <= (real)0.0f || shape <= (real)0.0f || rate <= (real)0.0f) return (real)0.0f;
  real log_pdf = shape * log(rate) - lgamma(shape) - (shape + (real)1.0f) * log(x) - (rate / x);
  return exp(log_pdf);
}

// Distribution (CDF): F_InvGamma(x; alpha, beta) = 1 - F_Gamma(1/x; alpha, 1/beta)
// Uses your existing pgamma(x, shape, rate)
static inline real pinvgamma(const real x, const real shape, const real rate) {
  if (x <= (real)0.0f || shape <= (real)0.0f || rate <= (real)0.0f) return (real)0.0f;
  return (real)1.0f - pgamma((real)1.0f / x, shape, rate);
}

// Quantile (QF): qinvgamma(p; alpha, beta) = 1 / qgamma(1 - p; alpha, 1/beta)
// Uses your existing qgamma(p, shape, rate)
static inline real qinvgamma(const real p, const real shape, const real rate) {
  if (shape <= (real)0.0f || rate <= (real)0.0f || p <= (real)0.0f) return (real)0.0f;
  if (p >= (real)1.0f) return INFINITY;
  real qg = qgamma((real)1.0f - p, shape, rate);
  if (qg <= (real)0.0f) return INFINITY;
  return (real)1.0f / qg;
}

// RNG: rinvgamma(alpha, beta) = 1 / rgamma(alpha, beta)
// Uses your existing rgamma(shape, rate)
static inline real rinvgamma_internal(const real shape, const real rate, __private int* idx, __private uint* mt) {
  // Hier rgamma_internal direkt aufrufen und die MT-Zeiger bitscharf weiterreichen!
  real g = rgamma_internal(shape, rate, idx, mt);
  if (g <= (real)0.0f) return (real)1e10f; // Schutzwall vor Division durch 0
  return (real)1.0f / g;
}
#define rinvgamma(shape, rate) rinvgamma_internal((shape), (rate), &idx, mt)

// =========================================================================
// beta distribution & student-t distribution (stabilized via continued fractions)
// =========================================================================

// Regularized Incomplete Beta Function I_x(a, b) ! RECURSION-FREE FOR OpenCL !
static inline real core_incomplete_beta(real x, real a, real b) {
  if (x <= (real)0.0f) return (real)0.0f;
  if (x >= (real)1.0f) return (real)1.0f;
  if (isnan(x) || isnan(a) || isnan(b)) return (real)NAN;
  
  int symmetric_flip = 0;
  real curr_x = x;
  real curr_a = a;
  real curr_b = b;
  
  if (x > (a + (real)1.0f) / (a + b + (real)2.0f)) {
    symmetric_flip = 1;
    curr_x = (real)1.0f - x;
    curr_a = b;
    curr_b = a;
  }
  
  real log_beta_const = lgamma(curr_a + curr_b) - (lgamma(curr_a) + lgamma(curr_b));
  real front = exp(log_beta_const + curr_a * log(curr_x) + curr_b * log((real)1.0f - curr_x));
  
  real safe_bound = (real)GPGPU_SAFE_MAX;
  if (safe_bound < (real)1e-7f) safe_bound = (real)1e-7f; 
  
  real qab = curr_a + curr_b;
  real qap = curr_a + (real)1.0f;
  real qam = curr_a - (real)1.0f;
  real c = (real)1.0f;
  
  real d = (real)1.0f - qab * curr_x / qap;
  if (fabs(d) < safe_bound) d = (d >= 0.0f) ? safe_bound : -safe_bound;
  d = (real)1.0f / d;
  real f = d;
  
  for (int m = 1; m <= 60; ++m) {
    real m_real = (real)m;
    real m2 = (real)2.0f * m_real;
    
    real aa = m_real * (curr_b - m_real) * curr_x / ((qam + m2) * (curr_a + m2));
    if (isnan(aa) || isinf(aa)) return (real)0.0f;
    
    d = (real)1.0f + aa * d;
    if (fabs(d) < safe_bound) d = (d >= 0.0f) ? safe_bound : -safe_bound;
    
    c = (real)1.0f + aa / (fabs(c) < safe_bound ? safe_bound : c);
    if (fabs(c) < safe_bound) c = (c >= 0.0f) ? safe_bound : -safe_bound;
    
    d = (real)1.0f / d;
    real delta = d * c;
    f *= delta;
    
    aa = -(curr_a + m_real) * (qab + m_real) * curr_x / ((curr_a + m2) * (qap + m2));
    if (isnan(aa) || isinf(aa)) return (real)0.0f;
    
    d = (real)1.0f + aa * d;
    if (fabs(d) < safe_bound) d = (d >= 0.0f) ? safe_bound : -safe_bound;
    
    c = (real)1.0f + aa / (fabs(c) < safe_bound ? safe_bound : c);
    if (fabs(c) < safe_bound) c = (c >= 0.0f) ? safe_bound : -safe_bound;
    
    d = (real)1.0f / d;
    delta = d * c;
    f *= delta;
    
    if (fabs(delta - (real)1.0f) < (real)GPGPU_EPSILON) {
      break;
    }
  }
  
  real result = front * f / curr_a;
  if (isnan(result) || isinf(result)) return (real)0.0f;
  
  if (symmetric_flip) return (real)1.0f - result;
  return result;
}


// Probability Density Function (PDF)
static inline real dbeta(real x, real shape1, real shape2) {
  if (shape1 <= (real)0.0f || shape2 <= (real)0.0f || x < (real)0.0f || x > (real)1.0f) return (real)0.0f;
  if (x == (real)0.0f) return (shape1 < (real)1.0f) ? (real)INFINITY : ((shape1 == (real)1.0f) ? shape2 : (real)0.0f);
  if (x == (real)1.0f) return (shape2 < (real)1.0f) ? (real)INFINITY : ((shape2 == (real)1.0f) ? shape1 : (real)0.0f);
  
  real log_beta_const = lgamma(shape1 + shape2) - (lgamma(shape1) + lgamma(shape2));
  real log_density = log_beta_const + (shape1 - (real)1.0f) * log(x) + (shape2 - (real)1.0f) * log((real)1.0f - x);
  return exp(log_density);
}

// Cumulative Distribution Function (CDF) via stable chain fraction
static inline real pbeta(real q, real shape1, real shape2) {
  return core_incomplete_beta(q, shape1, shape2);
}

// Quantile Function (Inverse CDF) via Newton-Raphson refinement
static inline real qbeta(real p, real shape1, real shape2) {
  if (p < (real)0.0f || p > (real)1.0f || shape1 <= (real)0.0f || shape2 <= (real)0.0f) return (real)NAN;
  if (p == (real)0.0f) return (real)0.0f;
  if (p == (real)1.0f) return (real)1.0f;
  
  real a = shape1;
  real b = shape2;
  
  // 1. Stable starting value (Mean)
  real guess = a / (a + b);
  
  // 2. Strict limits for hedging (bisection bracket)
  real lower = 0.0f;
  real upper = 1.0f;
  
  for (int i = 0; i < 35; ++i) {
    real current_p = pbeta(guess, a, b);
    real error = current_p - p;
    
    // Convergence criterion has also to work on FP32 Single Precision
    if (fabs(error) < (real)1e-5f) break;
    
    // Narrow bounds based on the sign of the error
    if (error > 0.0f) {
      upper = guess;
    } else {
      lower = guess;
    }
    
    // Use our own, highly precise dbeta function straight away!
    // This prevents any scaling mismatch with pbeta.
    real deriv = dbeta(guess, a, b);
    
    // 3. Numerical filter against unstable Newton steps
    if (deriv < (real)1e-6f || !isfinite(deriv)) {
      // Derivation too flat -> Force safe bisection step
      guess = (lower + upper) * (real)0.5f;
    } else {
      real step = error / deriv;
      real next_guess = guess - step;
      
      // Check whether the Newton step breaks out of the current bracket
      if (next_guess <= lower || next_guess >= upper || !isfinite(next_guess)) {
        guess = (lower + upper) * (real)0.5f;
      } else {
        guess = next_guess;
      }
    }
    
    // Machine accuracy protection (FP32!) for the next run
    if (guess <= (real)0.0f) guess = (real)1e-6f;
    if (guess >= (real)1.0f) guess = (real)0.99995f;
  }
  
  return guess;
}

// Internal RNG function (Stochastic mixture via two Gamma variables)
static inline real rbeta_internal(real shape1, real shape2, __private int* idx, __private uint* mt) {
  if (shape1 <= (real)0.0f || shape2 <= (real)0.0f) return (real)NAN;
  real y1 = rgamma_internal(shape1, (real)1.0f, idx, mt);
  real y2 = rgamma_internal(shape2, (real)1.0f, idx, mt);
  if (y1 + y2 == (real)0.0f) return (real)0.0f;
  return y1 / (y1 + y2);
}
#define rbeta(shape1, shape2) rbeta_internal((shape1), (shape2), &idx, mt)


// Student-t Probability Density Function (PDF)
static inline real dt(real x, int df) {
  if (df <= 0) return (real)0.0f;
  real log_numerator = lgamma(((real)df + (real)1.0f) * (real)0.5f);
  real log_denominator = (real)0.5f * log((real)df * (real)M_PI) + lgamma(df * (real)0.5f);
  real log_term = -(((real)df + (real)1.0f) * (real)0.5f) * log((real)1.0f + (x * x) / df);
  return exp(log_numerator - log_denominator + log_term);
}

// Student-t Cumulative Distribution Function (CDF) via incomplete beta identity
static inline real pt(real q, int df) {
  if (df <= 0) return (real)0.0f;
    real df_real = (real)df;
  
    real x = df_real / (df_real + q * q);

    real prob = (real)0.5f * pbeta(x, df_real * (real)0.5f, (real)0.5f);
  
  return (q > (real)0.0f) ? ((real)1.0f - prob) : prob;
}

// Student-t Quantile Function (Inverse CDF)
static inline real qt(real p, int df) {
  if (p < (real)0.0f || p > (real)1.0f || df <= 0) return (real)NAN;
  if (p == (real)0.0f) return (real)-INFINITY;
  if (p == (real)1.0f) return (real)INFINITY;
  if (p == (real)0.5f) return (real)0.0f;

  real df_real = (real)df;
  real z = qnorm(p, (real)0.0f, (real)1.0f);
  real guess = z + (z * z * z + z) / ((real)4.0f * df_real);
  
  for (int i = 0; i < 12; ++i) {
    real error = pt(guess, df) - p;
    if (fabs(error) < (real)1e-5f) break;
    real deriv = dt(guess, df);
    if (deriv == (real)0.0f) break;
    guess -= error / deriv;
  }
  return guess;
}

// Internal RNG function (Stochastic mixture: Z / sqrt(V / df))
static inline real rt_internal(int df, __private int* idx, __private uint* mt) {
  if (df <= 0) return (real)NAN;
  
  real u1 = mt_rand_01(idx, mt);
  real u2 = mt_rand_01(idx, mt);
  real z = sqrt((real)-2.0f * log(u1)) * cos((real)2.0f * (real)M_PI * u2);
  
  real v = rchisq_internal(df, idx, mt);
  
  return z / sqrt(v / (real)df);
}
#define rt(df) rt_internal((df), &idx, mt)


// =========================================================================
// f distribution
// =========================================================================

// Probability Density Function (PDF)
static inline real df(real x, int df1, int df2) {
  if (df1 <= 0 || df2 <= 0 || x < (real)0.0f) return (real)0.0f;
  if (x == (real)0.0f && df1 < 2) return (real)INFINITY;
  
  real log_numerator = ((real)df1 * (real)0.5f) * log((real)df1) + ((real)df2 * (real)0.5f) * log(df2) + lgamma((real)(df1 + df2) * (real)0.5f);
  real log_denominator = lgamma((real)df1 * (real)0.5f) + lgamma((real)df2 * (real)0.5f);
  real log_x_term = ((real)df1 * (real)0.5f - (real)1.0f) * log(x) - ((real)(df1 + df2) * (real)0.5f) * log((real)df1 * x + (real)df2);
  
  return exp(log_numerator - log_denominator + log_x_term);
}

// Cumulative Distribution Function (CDF) via fallback to the beta distribution
static inline real pf(real q, int df1, int df2) {
  if (df1 <= 0 || df2 <= 0) return (real)0.0f;
  if (q <= (real)0.0f) return (real)0.0f;
  real d1 = (real)df1;
  real d2 = (real)df2;
  real x = (d1 * q) / (d1 * q + d2);
  return pbeta(x, d1 * (real)0.5f, d2 * (real)0.5f);
}

// Quantile Function (Inverse CDF) via Newton-Raphson refinement
static inline real qf(real p, int df1, int df2) {
  if (p < (real)0.0f || p > (real)1.0f || df1 <= 0 || df2 <= 0) return (real)NAN;
  if (p == (real)0.0f) return (real)0.0f;
  if (p == (real)1.0f) return (real)INFINITY;
    
  real d1 = (real)df1;
  real d2 = (real)df2;
  
  real x = qbeta(p, d1 * (real)0.5f, d2 * (real)0.5f);
  real guess = (x * d2) / (d1 * ((real)1.0f - x));
  if (guess <= (real)0.0f) guess = (real)1e-5f;
  
  for (int i = 0; i < 10; ++i) {
    real error = pf(guess, df1, df2) - p;
    if (fabs(error) < (real)1e-6f) break;
    real deriv = df(guess, df1, df2);
    if (deriv == (real)0.0f) break;
    guess -= error / deriv;
    if (guess <= (real)0.0f) guess = (real)1e-5f;
  }
    return guess;
}

// Internal RNG function (Stochastic quotient of two chi-squared variables)
static inline real rf_internal(int df1, int df2, __private int* idx, __private uint* mt) {
  if (df1 <= 0 || df2 <= 0) return (real)NAN;
  
  real v1 = rchisq_internal(df1, idx, mt);
  real v2 = rchisq_internal(df2, idx, mt);
  
  if (v2 == (real)0.0f) return (real)INFINITY;
  return (v1 / (real)df1) / (v2 / (real)df2);
}
#define rf(df1, df2) rf_internal((df1), (df2), &idx, mt)


// =========================================================================
// log-normal distribution
// =========================================================================

// Probability Density Function (PDF)
static inline real dlnorm(real x, real meanlog, real sdlog) {
  if (sdlog <= (real)0.0f || x <= (real)0.0f) return (real)0.0f;
  // dnorm(log(x), meanlog, sdlog) / x
  return dnorm(log(x), meanlog, sdlog) / x;
}

// Cumulative Distribution Function (CDF)
static inline real plnorm(real q, real meanlog, real sdlog) {
  if (sdlog <= (real)0.0f) return (real)0.0f;
  if (q <= (real)0.0f) return (real)0.0f;
  // pnorm(log(q), meanlog, sdlog)
  return pnorm(log(q), meanlog, sdlog);
}

// Quantile Function (Inverse CDF)
static inline real qlnorm(real p, real meanlog, real sdlog) {
  if (p < (real)0.0f || p > (real)1.0f || sdlog <= (real)0.0f) return (real)NAN;
  if (p == (real)0.0f) return (real)0.0f;
  if (p == (real)1.0f) return (real)INFINITY;
  // exp(qnorm(p, meanlog, sdlog))
  return exp(qnorm(p, meanlog, sdlog));
}

// Internal RNG function (via exponentiated Normal distribution)
static inline real rlnorm_internal(real meanlog, real sdlog, __private int* idx, __private uint* mt) {
  if (sdlog <= (real)0.0f) return (real)NAN;
  
  // Generate standard normally distributed pair (Box-Muller)
  real u1 = mt_rand_01(idx, mt);
  real u2 = mt_rand_01(idx, mt);
  real z = sqrt((real)-2.0f * log(u1)) * cos((real)2.0f * (real)M_PI * u2);
  
  // Transformieren zu log-normal
  real y = meanlog + sdlog * z;
  return exp(y);
}

#define rlnorm(meanlog, sdlog) rlnorm_internal((meanlog), (sdlog), &idx, mt)

// =========================================================================
// cauchy distribution
// =========================================================================

// Probability Density Function (PDF)
static inline real dcauchy(real x, real location, real scale) {
  if (scale <= (real)0.0f) return (real)0.0f;
  real x_scaled = (x - location) / scale;
  return (real)(1.0f / M_PI) * (scale / (scale * scale + (x - location) * (x - location)));
}

// Cumulative Distribution Function (CDF)
static inline real pcauchy(real q, real location, real scale) {
  if (scale <= (real)0.0f) return (real)0.0f;
  return (real)0.5f + (real)(1.0f / M_PI) * atan((q - location) / scale);
}

// Quantile Function (Inverse CDF)
static inline real qcauchy(real p, real location, real scale) {
  if (p < (real)0.0f || p > (real)1.0f || scale <= (real)0.0f) return (real)NAN;
  if (p == (real)0.0f) return (real)-INFINITY;
  if (p == (real)1.0f) return (real)INFINITY;
  return location + scale * tan((real)M_PI * (p - (real)0.5f));
}

// Internal RNG function (via Inversion method)
static inline real rcauchy_internal(real location, real scale, __private int* idx, __private uint* mt) {
  if (scale <= (real)0.0f) return (real)NAN;
  real u = mt_rand_01(idx, mt);
  // Since mt_rand_01 lies in the interval [0, 1), this is mathematically absolutely stable
  return location + scale * tan((real)M_PI * (u - (real)0.5f));
}

#define rcauchy(location, scale) rcauchy_internal((location), (scale), &idx, mt)

// =========================================================================
// logistic distribution
// =========================================================================

// Probability Density Function (PDF)
static inline real dlogis(real x, real location, real scale) {
  if (scale <= (real)0.0f) return (real)0.0f;
  real z = (x - location) / scale;
  // Avoiding numerical overflows with extreme z values
  if (z > (real)50.0f || z < (real)-50.0f) return (real)0.0f;
  real e = exp(-z);
  return e / (scale * ((real)1.0f + e) * ((real)1.0f + e));
}

// Cumulative Distribution Function (CDF)
static inline real plogis(real q, real location, real scale) {
  if (scale <= (real)0.0f) return (real)0.0f;
  real z = (q - location) / scale;
  return (real)1.0f / ((real)1.0f + exp(-z));
}

// Quantile Function (Inverse CDF)
static inline real qlogis(real p, real location, real scale) {
  if (p < (real)0.0f || p > (real)1.0f || scale <= (real)0.0f) return (real)NAN;
  if (p == (real)0.0f) return (real)-INFINITY;
  if (p == (real)1.0f) return (real)INFINITY;
  return location + scale * log(p / ((real)1.0f - p));
}

// Internal RNG function (via Inversion method)
static inline real rlogis_internal(real location, real scale, __private int* idx, __private uint* mt) {
  if (scale <= (real)0.0f) return (real)NAN;
  real u = mt_rand_01(idx, mt);
  // Since u is in [0, 1), 1-u > 0, log() is safely protected from -Inf errors
  if (u == (real)0.0f) u = (real)1e-7f; 
  return location + scale * log(u / ((real)1.0f - u));
}

// 🎯 The macro hides the MT variables for the kernel call
#define rlogis(location, scale) rlogis_internal((location), (scale), &idx, mt)


// some linear algebra for model fitting
/**
 * Core component for lsfit(): Solves the linear balancing problem min ||A*x - b||^2
 * using Householder QR decomposition in a single thread.
 *
 * @param A_in Pointer to the m x n input matrix (row-major layout).
 * @param b_in Pointer to the m-dimensional vector of the right side.
 * @param m Number of measurement points / equations (m >= n).
 * @param n Number of parameters/unknowns.
 * @param x Target array (size n) for the calculated coefficients.
 * @return 0 on success, -1 on lack of rank or memory error.
 */

// NOT YET TESTED!!
// entry point: wls_gls_fit() below 

// =========================================================================
// lin-alg workspace for model fitting (without malloc / without zero)
// =========================================================================

static inline int core_qr_ls_solve(const real *A_in, const real *b_in, int m, int n, real *x, real *R, real *qty) {
    if (m < n || !A_in || !b_in || !x || !R || !qty) return -1;

    for (int i = 0; i < m * n; i++) R[i] = A_in[i];
    for (int i = 0; i < m; i++) qty[i] = b_in[i];

    for (int k = 0; k < n; k++) {
        real nrm2 = (real)0.0;
        for (int i = k; i < m; i++) nrm2 += R[i * n + k] * R[i * n + k];
        real norm = sqrt(nrm2);
        
        if (norm < (real)GPGPU_EPSILON) return -1;

        real ak = R[k * n + k];
        real alpha = (ak > (real)0.0) ? -norm : norm;
        real u1 = ak - alpha;
        
        if (fabs(u1) < (real)GPGPU_EPSILON) continue; 

        R[k * n + k] = alpha;

        real denom = alpha * u1;
        if (fabs(denom) < (real)GPGPU_EPSILON) denom = (denom < (real)0) ? -(real)GPGPU_EPSILON : (real)GPGPU_EPSILON;

        for (int j = k + 1; j < n; j++) {
            real dot = R[k * n + j];
            for (int i = k + 1; i < m; i++) {
                dot += (R[i * n + k] / u1) * R[i * n + j];
            }
            real beta = dot / denom;
            
            R[k * n + j] -= beta * u1;
            for (int i = k + 1; i < m; i++) R[i * n + j] -= beta * R[i * n + k];
        }

        real dot_b = qty[k];
        for (int i = k + 1; i < m; i++) {
            dot_b += (R[i * n + k] / u1) * qty[i];
        }
        real beta_b = dot_b / denom;
        
        qty[k] -= beta_b * u1;
        for (int i = k + 1; i < m; i++) qty[i] -= beta_b * R[i * n + k];
    }

    for (int i = n - 1; i >= 0; i--) {
        real sum = qty[i];
        for (int j = i + 1; j < n; j++) sum -= R[i * n + j] * x[j];
        if (fabs(R[i * n + i]) < (real)GPGPU_EPSILON) return -1;
        x[i] = sum / R[i * n + i];
    }
    return 0;
}

static inline int generate_poly_design_matrix_safe(const real *x_data, int m, int degree, real *A_out, real *x_min_out, real *x_scale_out) {
    if (!x_data || !A_out || m <= 0 || degree < 0 || !x_min_out || !x_scale_out) return -1;
    int n = degree + 1;

    real min_x = x_data[0];
    real max_x = x_data[0];
    for (int i = 1; i < m; i++) {
        if (x_data[i] < min_x) min_x = x_data[i];
        if (x_data[i] > max_x) max_x = x_data[i];
    }

    real range = max_x - min_x;
    if (fabs(range) < (real)GPGPU_EPSILON) range = (real)GPGPU_EPSILON; 

    *x_min_out = min_x;
    *x_scale_out = range;

    for (int i = 0; i < m; i++) {
        real x_norm = (x_data[i] - min_x) / range;
        A_out[i * n + 0] = (real)1.0;
        for (int j = 1; j < n; j++) {
            real val = A_out[i * n + (j - 1)] * x_norm;
            if (fabs(val) < (real)GPGPU_EPSILON) val = (real)0.0; 
            A_out[i * n + j] = val;
        }
    }
    return 0;
}

static inline int restore_original_coefficients(const real *c_norm, int degree, real x_min, real x_scale, real *a_orig, real *binom_space) {
    if (!c_norm || !a_orig || degree < 0 || !binom_space) return -1;
    if (fabs(x_scale) < (real)GPGPU_EPSILON) return -1;

    int n = degree + 1;
    for (int i = 0; i < n; i++) a_orig[i] = (real)0.0;
    for (int i = 0; i < n * n; i++) binom_space[i] = (real)0.0;

    for (int i = 0; i < n; i++) {
        binom_space[i * n + 0] = (real)1.0;
        for (int j = 1; j <= i; j++) {
            binom_space[i * n + j] = binom_space[(i - 1) * n + (j - 1)] + binom_space[(i - 1) * n + j];
        }
    }

    for (int j = 0; j < n; j++) {
        real c_val = c_norm[j];
        if (fabs(c_val) < (real)GPGPU_EPSILON) continue; 
        real inv_scale_pow = (real)1.0 / pow(x_scale, (real)j);
        
        for (int k = 0; k <= j; k++) {
            real b_coeff = binom_space[j * n + k];
            real min_pow = pow(-x_min, (real)(j - k));
            real term = c_val * inv_scale_pow * b_coeff * min_pow;
            if (fabs(term) < (real)GPGPU_EPSILON) term = (real)0.0;
            a_orig[k] += term;
        }
    }
    return 0;
}

static inline int core_cholesky(const real *Sigma, int m, real *L) {
    for (int i = 0; i < m * m; i++) L[i] = (real)0.0;
    for (int i = 0; i < m; i++) {
        for (int j = 0; j <= i; j++) {
            real sum = Sigma[i * m + j];
            for (int k = 0; k < j; k++) sum -= L[i * m + k] * L[j * m + k];
            if (i == j) {
                if (sum <= (real)GPGPU_EPSILON) return -1;
                L[i * m + j] = sqrt(sum);
            } else {
                real l_diag = L[j * m + j];
                if (fabs(l_diag) < (real)GPGPU_EPSILON) l_diag = (l_diag < (real)0) ? -(real)GPGPU_EPSILON : (real)GPGPU_EPSILON;
                L[i * m + j] = sum / l_diag;
            }
        }
    }
    return 0;
}

static inline void core_forward_substitute(const real *L, int m, const real *input, real *output) {
    for (int i = 0; i < m; i++) {
        real sum = input[i];
        for (int j = 0; j < i; j++) sum -= L[i * m + j] * output[j];
        real l_diag = L[i * m + i];
        if (fabs(l_diag) < (real)GPGPU_EPSILON) l_diag = (l_diag < (real)0) ? -(real)GPGPU_EPSILON : (real)GPGPU_EPSILON;
        output[i] = sum / l_diag;
    }
}

static inline int wls_gls_fit(const real *A_in, const real *b_in, int m, int n, 
                              const real *Sigma, const real *weights, real *x_out,
                              real *workspace_A_tilde, real *workspace_b_tilde,
                              real *workspace_L, real *workspace_col,
                              real *workspace_R, real *workspace_qty) {
    if (m < n || !A_in || !b_in || !x_out || !workspace_A_tilde || !workspace_b_tilde || !workspace_R || !workspace_qty) return -1;

    if (Sigma != 0) {
        if (!workspace_L || !workspace_col) return -1;
        if (core_cholesky(Sigma, m, workspace_L) != 0) return -1;
        core_forward_substitute(workspace_L, m, b_in, workspace_b_tilde);
        for (int j = 0; j < n; j++) {
            for (int i = 0; i < m; i++) workspace_col[i] = A_in[i * n + j];
            core_forward_substitute(workspace_L, m, workspace_col, workspace_R);
            for (int i = 0; i < m; i++) workspace_A_tilde[i * n + j] = workspace_R[i];
        }
    } else if (weights != 0) { 
        for (int i = 0; i < m; i++) {
            real w_sqrt = sqrt(weights[i]);
            workspace_b_tilde[i] = b_in[i] * w_sqrt;
            for (int j = 0; j < n; j++) workspace_A_tilde[i * n + j] = A_in[i * n + j] * w_sqrt;
        }
    } else {
        for (int i = 0; i < m * n; i++) workspace_A_tilde[i] = A_in[i];
        for (int i = 0; i < m; i++) workspace_b_tilde[i] = b_in[i];
    }
    return core_qr_ls_solve(workspace_A_tilde, workspace_b_tilde, m, n, x_out, workspace_R, workspace_qty);
}

static inline int ls_poly_fit(const real *x_data, const real *y_data, int m, int degree, real *a_out, real *total_workspace) {
    if (!x_data || !y_data || !a_out || degree < 0 || m < (degree + 1) || !total_workspace) return -1;
    int n = degree + 1;

    real *A_design    = total_workspace;
    real *c_norm      = A_design + (m * n);
    real *A_tilde     = c_norm + n;
    real *b_tilde     = A_tilde + (m * n);
    real *binom_space = b_tilde + m; 
    
    real *workspace_R   = A_tilde; 
    real *workspace_qty = b_tilde;

    real x_min = (real)0.0;
    real x_scale = (real)1.0;

    if (generate_poly_design_matrix_safe(x_data, m, degree, A_design, &x_min, &x_scale) != 0) return -1;
    if (wls_gls_fit(A_design, y_data, m, n, 0, 0, c_norm, A_tilde, b_tilde, 0, 0, workspace_R, workspace_qty) != 0) return -1;
    if (restore_original_coefficients(c_norm, degree, x_min, x_scale, a_out, binom_space) != 0) return -1;

    return 0; 
}
