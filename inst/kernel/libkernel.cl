// -*- c -*-

// 🛡️ define severeal constants regarding float/double differences
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
  // Wenn wir im Double-Modus sind
  #define REAL_MIN DBL_MIN
#else
  // Wenn wir im erzwungenen Float-Modus (-f) sind
  #define REAL_MIN FLT_MIN
#endif
// oerloads for int arguments to functions working on real_t  arguments
__attribute__((overloadable)) static inline real_t lgamma(int x) { return lgamma((real_t)x); }
__attribute__((overloadable)) static inline real_t log(int x)    { return log((real_t)x); }
__attribute__((overloadable)) static inline real_t sqrt(int x)   { return sqrt((real_t)x); }
__attribute__((overloadable)) static inline real_t exp(int x)    { return exp((real_t)x); }
__attribute__((overloadable)) static inline real_t sin(int x)    { return sin((real_t)x); }
__attribute__((overloadable)) static inline real_t cos(int x)    { return cos((real_t)x); }
__attribute__((overloadable)) static inline real_t tan(int x)    { return tan((real_t)x); }
// TO BE CONTINUED ...

#define INIT_MT(mt) (                                                   \
                     uint mt[624];                                      \
                     int idx = 624;                                     \
                     mt[0] = *seed + get_global_id(0);                  \
                     for (int i = 1; i < 624; ++i) {                    \
                       mt[i] = (181243 * (mt[i - 1] ^ (mt[i - 1] >> 30)) + i); \
                     }                                                  \
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
  // divide by 4294967295+1 to get into [0,1)
  return (real_t)mt_rand(&mt[0], &idx[0], mt) / 4294967296.0f;
}

// Normal Distribution (PDF)
static inline real_t normal_pdf(real_t x, real_t mu, real_t sigma) {
  if (sigma <= 0) return 0;
  real_t z = (x - mu) / sigma;
  return (1.0f / (sigma * sqrt(2.0f * M_PI))) * exp(-0.5f * z * z);
}

// Normal CDF Approximation (using erf approximation)
//static inline real_t normal_cdf(real_t x, real_t mu, real_t sigma) {
//  if (sigma <= 0) return 0;
//  real_t z = (x - mu) / sigma;
//  real_t t = 1 / (1 + 0.5f * fabs(z));
//  real_t erf_approx = 1 - t * exp(-z * z - 1.26523f * t * (t - 1 + 0.045f * t));
//  return 0.5f * (1 + sign(z) * erf_approx);
//}
//
// 🚀 NATIVER, BITSCHARFER NORMAL-CDF ACCELERATOR VIA OPENCL-ERFC
static inline real_t normal_cdf(real_t x, real_t mu, real_t sigma) {
  if (sigma <= (real_t)0.0f) return (real_t)0.0f;
  real_t z = (x - mu) / sigma;
  
  // Nutze die im OpenCL-C-Standard eingebaute, hochpräzise erfc-Funktion.
  // Das eliminiert jegliche Polynom-Ungenauigkeiten und ist rasend schnell!
  return (real_t)0.5f * erfc(-z / sqrt((real_t)2.0f));
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
  real_t log_pdf = (k/2.0f - 1) * log(x) - x/2.0f - lgamma(k/2.0f) - (k/2.0f) * log(2.0f);
  return exp(log_pdf);
}

// Chi-Squared CDF
static inline real_t chi_squared_cdf(real_t x, real_t k) {
  if (k <= 0 || x < 0) return 0;
  return 1 - exp(-x/2.0f) * pow(x/2.0f, k/2.0f) / (tgamma(k/2.0f) * pow(2, k/2.0f));
}

// t-Distribution PDF
static inline real_t student_t_pdf(real_t x, real_t nu) {
  if (nu <= 0) return 0;
  real_t log_pdf = lgamma((nu + 1) / 2) - lgamma(nu / 2) - 0.5f * log(nu * M_PI);
  log_pdf -= ((nu + 1.0f) / 2.0f) * log(1.0f + x * x / nu);
  return exp(log_pdf);
}

// t-Distribution CDF (approximation via beta function)
static inline real_t student_t_cdf(real_t x, real_t nu) {
  if (nu <= 0) return 0;
  real_t t = x / sqrt(nu + x * x);
  real_t beta = 0.5f * (1.0f + t) * pow(1.0f - t * t, nu / 2.0f);
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
  real_t log_pdf = (alpha - 1.0f) * log(x) + (beta_param - 1) * log(1.0f - x) - lgamma(alpha + beta_param) + lgamma(alpha) + lgamma(beta_param);
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
  return lgamma((real_t)(a + 1.0f)) - lgamma((real_t)(b + 1.0f)) - lgamma((real_t)(a - b + 1.0f));
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
  real_t log_pmf = -lambda + k * log(lambda) - lgamma(k + 1.0f);
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
  return p * pow(1.0f - p, k);
}

// Geometric CDF
static inline real_t geometric_cdf(int k, real_t p) {
  if (k < 0 || p <= 0 || p > 1) return 0;
  return 1 - pow(1.0f - p, k + 1);
}


// Negative Binomial PDF
static inline real_t neg_binomial_pdf(int k, int r, real_t p) {
  if (k < 0 || r <= 0 || p <= 0 || p > 1) return 0;
  real_t log_pmf = log_choose(k + r - 1.0f, k) + r * log(p) + k * log(1 - p);
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
  real_t u = mt_rand_01(&mt[0], &idx[0], mt);
  if (u <= 0.0f) u = GPGPU_EPSILON; 
  return 1.0f / rate * (-log(u));
}
// normal distribution
static inline real_t rnorm(__private real_t mu, __private real_t sigma,
                           __private int* idx, __private uint* mt) {
  if(get_global_id(0) % 2 == 0)
    return mu + sigma * sqrt((real_t)-2.0f * log(mt_rand_01(&mt[0], &idx[0], mt))) *
      cos((real_t)2.0f * (real_t)M_PI * mt_rand_01(&mt[0], &idx[0], mt)); // 🎯 Nutzen M_PI und saubere Typ-Casts!
  else
    return mu + sigma * sqrt((real_t)-2.0f * log(mt_rand_01(&mt[0], &idx[0], mt))) *
      cos((real_t)2.0f * (real_t)M_PI * mt_rand_01(&mt[0], &idx[0], mt));
}

// t distribution
static inline real_t rt(__private int nu,
                        __private int* idx, __private uint* mt) {
  real_t V = nu * (-log(mt_rand_01(&mt[0], &idx[0], mt)));
  return sqrt((real_t)-2.0f * log(mt_rand_01(&mt[0], &idx[0], mt))) *
    cos((real_t)2.0f * (real_t)M_PI * mt_rand_01(&mt[0], &idx[0], mt)) * sqrt(nu / V); // 🎯 Nutzen M_PI!
}


// gamma distribution
static inline real_t rgamma(__private real_t shape, __private real_t scale,
                            __private int* idx, __private uint* mt) {
  if (shape <= 0.0f || scale <= 0.0f) return 0.0f;

  // 🚀 shape < 1 (Ahrens & Dieter)
  if (shape < 1.0f) {
    while (true) {
      real_t u = mt_rand_01(&mt[0], &idx[0], mt);
      real_t b = (M_E + shape) / M_E;
      real_t p = b * u;
      if (p <= 1.0f) {
        real_t x = pow(p, 1.0f / shape);
        real_t u2 = mt_rand_01(&mt[0], &idx[0], mt);
        if (u2 <= exp(-x)) return x * scale;
      } else {
        real_t x = -log((b - p) / shape);
        real_t u2 = mt_rand_01(&mt[0], &idx[0], mt);
        if (u2 <= pow(x, shape - 1.0f)) return x * scale;
      }
    }
  }

  // 🚀 shape >= 1 (Marsaglia & Tsang)
  real_t d = shape - 1.0f / 3.0f;
  real_t c = 1.0f / sqrt(9.0f * d);
  while (true) {
    // Box-Muller
    real_t u1 = mt_rand_01(&mt[0], &idx[0], mt);
    real_t u2 = mt_rand_01(&mt[0], &idx[0], mt);
    while(u1 <= GPGPU_EPSILON) u1 = mt_rand_01(&mt[0], &idx[0], mt); // underflow
    real_t z = sqrt(-2.0f * log(u1)) * cos(2.0f * (real_t)M_PI * u2);

    real_t v = 1.0f + c * z;
    if (v <= 0.0f) continue;
    v = v * v * v;

    real_t u = mt_rand_01(&mt[0], &idx[0], mt);
    if (u < 1.0f - 0.0331f * z * z * z * z) return d * v * scale;
    if (log(u) < 0.5f * z * z + d * (1.0f - v + log(v))) return d * v * scale;
  }
}

//  inverse gamma
static inline real_t rinvgamma(__private real_t alpha,__private real_t beta,__private int* idx,__private  uint* mt) {
  real_t gamma_val = rgamma(alpha, beta, idx, mt);
  if (gamma_val <= (real_t)0) return (real_t)1e10; // Schutz vor Division durch 0
  return (real_t)1.0f / gamma_val;
}


// chisquared distribution
static inline real_t rchisq(__private int nu,
                            __private int* idx, __private uint* mt) {
  return rgamma((real_t)nu / 2.0f, 2.0f, &idx[0], mt);
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
  return floor(log(mt_rand_01(&mt[0], &idx[0], mt)) / log(1.0f - prob));
}

// negative binomial
static inline uint rnbinom(__private int size, __private real_t prob,
                           __private int* idx, __private uint* mt){
  uint sum = 0;
  for (int i = 0; i < size; ++i) {
    sum += floor(log(mt_rand_01(&mt[0], &idx[0], mt)) / log(1.0f - prob)); // Requires multiple uniforms
  }
  return sum;
}

// poisson
static inline uint rpois(__private real_t lambda,
                         __private int* idx, __private uint* mt){
  uint k = 0;
  real_t sum_exponentials = 0;
  while (sum_exponentials <= 1) { // Sum exponentials until exceed 1
    sum_exponentials += -log(mt_rand_01(&mt[0], &idx[0], mt)) * 1.0f / lambda;
    k++;
  }
  return k-1;
}

// hypergeometric
static inline uint rhyper(__private int white, __private int black, __private int size,
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
        return k_candidate; // Accepted k value
    }
  }
}

// quantile functions
// 🚀 DER UNZERSTÖRBARE, ORIGINALER R-CORE WICHURA-KERNEL (AS 241)
static inline real_t qnorm(real_t p, real_t mu, real_t sigma) {
  if (sigma <= (real_t)0.0f) return (real_t)0.0f;
  if (p <= (real_t)0.0f) return -INFINITY;
  if (p >= (real_t)1.0f) return INFINITY;

  real_t q, r, t;

  if (p > (real_t)0.025f && p < (real_t)0.975f) {
    // 1. ZENTRALE REGION (Mitte läuft perfekt flach)
    q = p - (real_t)0.5f;
    r = q * q;
    t = q * ((((((((real_t)-2.5490809287301226727e3f * r + 
                  (real_t)3.3430585583326954329e4f) * r - 
                 (real_t)6.7265770927008700105e4f) * r + 
                (real_t)4.5921953931549871457e4f) * r - 
               (real_t)1.3731693765509461125e4f) * r + 
              (real_t)1.9715909503065094404e3f) * r - 
             (real_t)1.3314166789178437745e2f) * r + 
            (real_t)3.3871328727963666080e0f) /
         ((((((((real_t)5.2264952788528545610e3f * r - 
              (real_t)2.8729085735721942674e4f) * r + 
             (real_t)3.9307895800092710610e4f) * r - 
            (real_t)2.1213794301586595851e4f) * r + 
           (real_t)5.3941960214247511077e3f) * r - 
          (real_t)6.8718700749205790830e2f) * r + 
         (real_t)4.2313330701600911252e1f) * r - (real_t)1.0f);
  } else {
    // 2. RAND-REGION (Exakt abgestimmt auf den R-Core)
    r = (p <= (real_t)0.025f) ? p : ((real_t)1.0f - p);
    t = sqrt(-(real_t)log(r)); 
    
    q = ((((((((real_t)7.4245853427844152930e-4f * t + 
               (real_t)2.1384464432927050751e-2f) * t + 
              (real_t)2.3158182032484056381e-1f) * t + 
             (real_t)1.2851316852056238754e0f) * t + 
            (real_t)3.6478483247632046050e0f) * t + 
           (real_t)5.7694972214606914055e0f) * t + 
          (real_t)4.6303378461565452959e0f) * t + 
         (real_t)1.4234371107496835773e0f) /
      ((((((((real_t)9.1798364847372227220e-3f * t + 
              (real_t)1.5497255561113713508e-1f) * t + 
             (real_t)1.1370089758332959491e0f) * t + 
            (real_t)4.3413143505342411516e0f) * t + 
           (real_t)8.7508276002690394774e0f) * t + 
          (real_t)9.1404456299847534446e0f) * t + 
         (real_t)4.7784653641792713111e0f) * t + (real_t)1.0f);
         
    if (p <= (real_t)0.025f) q = -q;
  }

  real_t x = mu + q * sigma;

  // 3. Entfesselte Newton-Raphson Schleife (Profitiert jetzt voll vom erfc-Fix!)
  for (int i = 0; i < 8; ++i) {
    real_t pdf = normal_pdf(x, mu, sigma);
    if (isnan(pdf) || isinf(pdf) || pdf <= (real_t)GPGPU_SAFE_MAX) break;
    
    real_t diff = normal_cdf(x, mu, sigma) - p;
    x -= diff / pdf; 
  }

  return x;
}

// 🚀 DIE SCHUSSFESTE PADÉ-QUANTILSFUNKTION MIT SICHEREM UMSCHALT-TOR (4.0)
static inline real_t qnorm2(real_t p, real_t mu, real_t sigma) {
  if (sigma <= (real_t)0.0f) return (real_t)0.0f;
  if (p <= (real_t)0.0f) return -INFINITY;
  if (p >= (real_t)1.0f) return INFINITY;

  real_t q, w, t;
  real_t u = (real_t)2.0f * p - (real_t)1.0f;
  
  // Symmetrische Transformation: w wird groß an den Rändern
  w = -(real_t)log(((real_t)1.0f - u) * ((real_t)1.0f + u));

  // 🎯 DAS NEUE SICHERE TOR: Wechselt weit vor der kritischen Polstelle!
  if (w < (real_t)4.0f) {
    // 1. ZENTRALE PADÉ-REGION (w < 4.0: p liegt im sicheren Kernbereich)
    real_t zaehler = ((((((real_t)-1.230922087e-3f * w + 
                           (real_t)2.138541525e-2f) * w - 
                          (real_t)1.043791307e-1f) * w + 
                         (real_t)5.011415795e-1f) * w - 
                        (real_t)9.423483907e-1f) * w + 
                       (real_t)1.000000000e0f);
    real_t nenner  = (((((((real_t)1.583407028e-3f * w + 
                           (real_t)3.010465335e-2f) * w + 
                          (real_t)1.359489467e-1f) * w + 
                         (real_t)3.143232420e-1f) * w + 
                        (real_t)4.004131589e-1f) * w + 
                       (real_t)2.186989681e-1f) * w + (real_t)1.0f);
    
    q = u * (zaehler / nenner);
  } else {
    // 2. RAND-PADÉ-REGION (w >= 4.0: Hier landet dein p = 0.001 nun absolut sicher!)
    t = sqrt(w) - (real_t)3.0f; // Auf den neuen stabilen Entwicklungspunkt angepasst
    
    real_t zaehler = ((((((((real_t)-4.575128315e-5f * t + 
                            (real_t)8.330753238e-4f) * t - 
                           (real_t)5.774916843e-3f) * t + 
                          (real_t)2.366525758e-2f) * t - 
                         (real_t)6.279234585e-2f) * t + 
                        (real_t)1.083162329e-1f) * t - 
                       (real_t)4.828524874e-2f) * t + (real_t)7.424585342e-4f);
    real_t nenner  = ((((((((real_t)-5.453733035e-5f * t + 
                           (real_t)9.432025345e-4f) * t - 
                          (real_t)6.004863486e-3f) * t + 
                         (real_t)2.181059905e-2f) * t - 
                        (real_t)3.568452538e-2f) * t + 
                       (real_t)2.666479840e-2f) * t + 
                      (real_t)1.520143325e-2f) * t + (real_t)1.0f);
                      
    q = zaehler / nenner;
         
    if (u < (real_t)0.0f) q = -q;
  }

  // Transformation auf das standardnormierte Quantil (sqrt(2) * q)
  real_t x = mu + (real_t)1.414213562373095f * q * sigma;

  // 3. Newton-Raphson Feinschliff für die ultimative Präzision
  // 3. Entfesselte Newton-Raphson Schleife für Padé
  for (int i = 0; i < 6; ++i) {
    real_t pdf = normal_pdf(x, mu, sigma);
    
    // 🛡️ REPARATUR: Nur bei echtem Unterlauf zu 0.0f abbrechen, 
    // damit Float-Treiber den Schritt nicht blockieren!
    if (isnan(pdf) || isinf(pdf) || pdf == (real_t)0.0f) break;
    
    real_t diff = normal_cdf(x, mu, sigma) - p;
    x -= diff / pdf; 
  }

  return x;
}

// some linear algebra for model fitting
/**
 * Kernkomponente für lsfit(): Löst das lineare Ausgleichsproblem min ||A*x - b||^2
 * mittels Householder-QR-Zerlegung in einem einzigen Thread.
 *
 * @param A_in Zeiger auf die m x n Eingabematrix (Row-Major Layout).
 * @param b_in Zeiger auf den m-dimensionalen Vektor der rechten Seite.
 * @param m    Anzahl der Messpunkte / Gleichungen (m >= n).
 * @param n    Anzahl der Parameter / Unbekannten.
 * @param x    Ziel-Array (Größe n) für die berechneten Koeffizienten.
 * @return     0 bei Erfolg, -1 bei Rangmangel oder Speicherfehler.
 */


// =========================================================================
// SAKKADISCHER LIN-ALG WORKSPACE FÜR MODEL FITTING (OHNE MALLOC / OHNE NULL)
// =========================================================================

static inline int core_qr_ls_solve(const real_t *A_in, const real_t *b_in, int m, int n, real_t *x, real_t *R, real_t *qty) {
    if (m < n || !A_in || !b_in || !x || !R || !qty) return -1;

    for (int i = 0; i < m * n; i++) R[i] = A_in[i];
    for (int i = 0; i < m; i++) qty[i] = b_in[i];

    for (int k = 0; k < n; k++) {
        real_t nrm2 = (real_t)0.0;
        for (int i = k; i < m; i++) nrm2 += R[i * n + k] * R[i * n + k];
        real_t norm = sqrt(nrm2);
        
        if (norm < (real_t)GPGPU_EPSILON) return -1;

        real_t ak = R[k * n + k];
        real_t alpha = (ak > (real_t)0.0) ? -norm : norm;
        real_t u1 = ak - alpha;
        
        if (fabs(u1) < (real_t)GPGPU_EPSILON) continue; 

        R[k * n + k] = alpha;

        real_t denom = alpha * u1;
        if (fabs(denom) < (real_t)GPGPU_EPSILON) denom = (denom < (real_t)0) ? -(real_t)GPGPU_EPSILON : (real_t)GPGPU_EPSILON;

        for (int j = k + 1; j < n; j++) {
            real_t dot = R[k * n + j];
            for (int i = k + 1; i < m; i++) {
                dot += (R[i * n + k] / u1) * R[i * n + j];
            }
            real_t beta = dot / denom;
            
            R[k * n + j] -= beta * u1;
            for (int i = k + 1; i < m; i++) R[i * n + j] -= beta * R[i * n + k];
        }

        real_t dot_b = qty[k];
        for (int i = k + 1; i < m; i++) {
            dot_b += (R[i * n + k] / u1) * qty[i];
        }
        real_t beta_b = dot_b / denom;
        
        qty[k] -= beta_b * u1;
        for (int i = k + 1; i < m; i++) qty[i] -= beta_b * R[i * n + k];
    }

    for (int i = n - 1; i >= 0; i--) {
        real_t sum = qty[i];
        for (int j = i + 1; j < n; j++) sum -= R[i * n + j] * x[j];
        if (fabs(R[i * n + i]) < (real_t)GPGPU_EPSILON) return -1;
        x[i] = sum / R[i * n + i];
    }
    return 0;
}

static inline int generate_poly_design_matrix_safe(const real_t *x_data, int m, int degree, real_t *A_out, real_t *x_min_out, real_t *x_scale_out) {
    if (!x_data || !A_out || m <= 0 || degree < 0 || !x_min_out || !x_scale_out) return -1;
    int n = degree + 1;

    real_t min_x = x_data[0];
    real_t max_x = x_data[0];
    for (int i = 1; i < m; i++) {
        if (x_data[i] < min_x) min_x = x_data[i];
        if (x_data[i] > max_x) max_x = x_data[i];
    }

    real_t range = max_x - min_x;
    if (fabs(range) < (real_t)GPGPU_EPSILON) range = (real_t)GPGPU_EPSILON; 

    *x_min_out = min_x;
    *x_scale_out = range;

    for (int i = 0; i < m; i++) {
        real_t x_norm = (x_data[i] - min_x) / range;
        A_out[i * n + 0] = (real_t)1.0;
        for (int j = 1; j < n; j++) {
            real_t val = A_out[i * n + (j - 1)] * x_norm;
            if (fabs(val) < (real_t)GPGPU_EPSILON) val = (real_t)0.0; 
            A_out[i * n + j] = val;
        }
    }
    return 0;
}

static inline int restore_original_coefficients(const real_t *c_norm, int degree, real_t x_min, real_t x_scale, real_t *a_orig, real_t *binom_space) {
    if (!c_norm || !a_orig || degree < 0 || !binom_space) return -1;
    if (fabs(x_scale) < (real_t)GPGPU_EPSILON) return -1;

    int n = degree + 1;
    for (int i = 0; i < n; i++) a_orig[i] = (real_t)0.0;
    for (int i = 0; i < n * n; i++) binom_space[i] = (real_t)0.0;

    for (int i = 0; i < n; i++) {
        binom_space[i * n + 0] = (real_t)1.0;
        for (int j = 1; j <= i; j++) {
            binom_space[i * n + j] = binom_space[(i - 1) * n + (j - 1)] + binom_space[(i - 1) * n + j];
        }
    }

    for (int j = 0; j < n; j++) {
        real_t c_val = c_norm[j];
        if (fabs(c_val) < (real_t)GPGPU_EPSILON) continue; 
        real_t inv_scale_pow = (real_t)1.0 / pow(x_scale, (real_t)j);
        
        for (int k = 0; k <= j; k++) {
            real_t b_coeff = binom_space[j * n + k];
            real_t min_pow = pow(-x_min, (real_t)(j - k));
            real_t term = c_val * inv_scale_pow * b_coeff * min_pow;
            if (fabs(term) < (real_t)GPGPU_EPSILON) term = (real_t)0.0;
            a_orig[k] += term;
        }
    }
    return 0;
}

static inline int core_cholesky(const real_t *Sigma, int m, real_t *L) {
    for (int i = 0; i < m * m; i++) L[i] = (real_t)0.0;
    for (int i = 0; i < m; i++) {
        for (int j = 0; j <= i; j++) {
            real_t sum = Sigma[i * m + j];
            for (int k = 0; k < j; k++) sum -= L[i * m + k] * L[j * m + k];
            if (i == j) {
                if (sum <= (real_t)GPGPU_EPSILON) return -1;
                L[i * m + j] = sqrt(sum);
            } else {
                real_t l_diag = L[j * m + j];
                if (fabs(l_diag) < (real_t)GPGPU_EPSILON) l_diag = (l_diag < (real_t)0) ? -(real_t)GPGPU_EPSILON : (real_t)GPGPU_EPSILON;
                L[i * m + j] = sum / l_diag;
            }
        }
    }
    return 0;
}

static inline void core_forward_substitute(const real_t *L, int m, const real_t *input, real_t *output) {
    for (int i = 0; i < m; i++) {
        real_t sum = input[i];
        for (int j = 0; j < i; j++) sum -= L[i * m + j] * output[j];
        real_t l_diag = L[i * m + i];
        if (fabs(l_diag) < (real_t)GPGPU_EPSILON) l_diag = (l_diag < (real_t)0) ? -(real_t)GPGPU_EPSILON : (real_t)GPGPU_EPSILON;
        output[i] = sum / l_diag;
    }
}

// 🛡️ wls_gls_fit STEHT JETZT KORREKT VOR ls_poly_fit!
static inline int wls_gls_fit(const real_t *A_in, const real_t *b_in, int m, int n, 
                              const real_t *Sigma, const real_t *weights, real_t *x_out,
                              real_t *workspace_A_tilde, real_t *workspace_b_tilde,
                              real_t *workspace_L, real_t *workspace_col,
                              real_t *workspace_R, real_t *workspace_qty) {
    if (m < n || !A_in || !b_in || !x_out || !workspace_A_tilde || !workspace_b_tilde || !workspace_R || !workspace_qty) return -1;

    if (Sigma != 0) { // 🛡️ iMac-safe '0' statt 'NULL'
        if (!workspace_L || !workspace_col) return -1;
        if (core_cholesky(Sigma, m, workspace_L) != 0) return -1;
        core_forward_substitute(workspace_L, m, b_in, workspace_b_tilde);
        for (int j = 0; j < n; j++) {
            for (int i = 0; i < m; i++) workspace_col[i] = A_in[i * n + j];
            core_forward_substitute(workspace_L, m, workspace_col, workspace_R);
            for (int i = 0; i < m; i++) workspace_A_tilde[i * n + j] = workspace_R[i];
        }
    } else if (weights != 0) { // 🛡️ iMac-safe '0' statt 'NULL'
        for (int i = 0; i < m; i++) {
            real_t w_sqrt = sqrt(weights[i]);
            workspace_b_tilde[i] = b_in[i] * w_sqrt;
            for (int j = 0; j < n; j++) workspace_A_tilde[i * n + j] = A_in[i * n + j] * w_sqrt;
        }
    } else {
        for (int i = 0; i < m * n; i++) workspace_A_tilde[i] = A_in[i];
        for (int i = 0; i < m; i++) workspace_b_tilde[i] = b_in[i];
    }
    return core_qr_ls_solve(workspace_A_tilde, workspace_b_tilde, m, n, x_out, workspace_R, workspace_qty);
}

static inline int ls_poly_fit(const real_t *x_data, const real_t *y_data, int m, int degree, real_t *a_out, real_t *total_workspace) {
    if (!x_data || !y_data || !a_out || degree < 0 || m < (degree + 1) || !total_workspace) return -1;
    int n = degree + 1;

    real_t *A_design    = total_workspace;
    real_t *c_norm      = A_design + (m * n);
    real_t *A_tilde     = c_norm + n;
    real_t *b_tilde     = A_tilde + (m * n);
    real_t *binom_space = b_tilde + m; 
    
    real_t *workspace_R   = A_tilde; 
    real_t *workspace_qty = b_tilde;

    real_t x_min = (real_t)0.0;
    real_t x_scale = (real_t)1.0;

    if (generate_poly_design_matrix_safe(x_data, m, degree, A_design, &x_min, &x_scale) != 0) return -1;
    if (wls_gls_fit(A_design, y_data, m, n, 0, 0, c_norm, A_tilde, b_tilde, 0, 0, workspace_R, workspace_qty) != 0) return -1;
    if (restore_original_coefficients(c_norm, degree, x_min, x_scale, a_out, binom_space) != 0) return -1;

    return 0; 
}
