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
// oerloads for int arguments to functions working on real  arguments
__attribute__((overloadable)) static inline real lgamma(int x) { return lgamma((real)x); }
__attribute__((overloadable)) static inline real log(int x)    { return log((real)x); }
__attribute__((overloadable)) static inline real sqrt(int x)   { return sqrt((real)x); }
__attribute__((overloadable)) static inline real exp(int x)    { return exp((real)x); }
__attribute__((overloadable)) static inline real sin(int x)    { return sin((real)x); }
__attribute__((overloadable)) static inline real cos(int x)    { return cos((real)x); }
__attribute__((overloadable)) static inline real tan(int x)    { return tan((real)x); }
// TO BE CONTINUED ...

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

// --- Beta Distribution ---
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
  
  // Nutze die im OpenCL-C-Standard eingebaute, hochpräzise erfc-Funktion.
  // Das eliminiert jegliche Polynom-Ungenauigkeiten und ist rasend schnell!
  return (real)0.5f * erfc(-z / sqrt((real)2.0f));
}

// Quantile
static inline real qnorm(real p, real mu, real sigma) {
  if (sigma <= (real)0.0f) return (real)0.0f;
  if (p <= (real)0.0f) return -INFINITY;
  if (p >= (real)1.0f) return INFINITY;

  real q, r, t;

  if (p > (real)0.025f && p < (real)0.975f) {
    // 1. ZENTRALE REGION (Mitte läuft perfekt flach)
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
    // 2. RAND-REGION (Exakt abgestimmt auf den R-Core)
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

  // 3. Entfesselte Newton-Raphson Schleife (Profitiert jetzt voll vom erfc-Fix!)
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
  // Da 'mt' und 'idx' bereits Pointer sind, reichen wir sie DIREKT weiter!
  real u1 = mt_rand_01(&idx[0], mt);
  real u2 = mt_rand_01(&idx[0], mt);
  if(get_global_id(0) % 2 == 1)
    return mu + sigma * sqrt((real)-2.0f * log(u1)) *
           cos((real)2.0f * (real)M_PI * u2);
  else
    return mu + sigma * sqrt((real)-2.0f * log(u1)) *
           sin((real)2.0f * (real)M_PI * u2); // 💡 Tipp: Zweiter Zweig nutzt meist 'sin' für Box-Muller
}
#define rnorm(mu, sigma) rnorm_internal((mu), (sigma), &idx, mt)


// =========================================================================
// UNIFORM DISTRIBUTION 
// =========================================================================

// Dichte (PDF)
static inline real dunif(real x, real min, real max) {
  if (x < min || x > max || min >= max) return (real)0.0f;
  return (real)1.0f / (max - min);
}

// Verteilungsfunktion (CDF)
static inline real punif(real q, real min, real max) {
  if (min >= max || q < min) return (real)0.0f;
  if (q >= max) return (real)1.0f;
  return (q - min) / (max - min);
}

// Quantilfunktion (Inverse CDF)
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
// POISSON DISTRIBUTION (Poisson-Verteilung)
// =========================================================================

// Wahrscheinlichkeitsfunktion (PMF / Dichte)
static inline real dpois(real x, real lambda) {
  if (lambda < (real)0.0f || x < (real)0.0f) return (real)0.0f;
  // Hinweis: Nutzt intern deine math.cl-Hilfsfunktionen (z.B. lgamma oder exp/pow)
  // Für diskrete Werte sollte x eine Ganzzahl sein.
  real k = floor(x);
  if (k != x) return (real)0.0f;
  
  // Alternative über Log-Skala zur Vermeidung von Overflows: exp(-lambda + k*log(lambda) - lgamma(k + 1))
  return exp(-lambda + k * log(lambda) - lgamma(k + (real)1.0f));
}

// Verteilungsfunktion (CDF)
static inline real ppois(real q, real lambda) {
  if (lambda < (real)0.0f) return (real)0.0f;
  if (q < (real)0.0f) return (real)0.0f;
  
  // Nutze die unvollständige Gammafunktion (regularized gamma Q oder P) falls vorhanden,
  // oder eine klassische iterative Schleife für kleine/mittlere Lambdas:
  real k = floor(q);
  real sum = (real)0.0f;
  for (int i = 0; i <= (int)k; ++i) {
    sum += exp(-lambda + (real)i * log(lambda) - lgamma((real)i + (real)1.0f));
  }
  return sum;
}

// Quantilfunktion (Inverse CDF)
static inline int qpois(real p, real lambda) {
  if (p < (real)0.0f || p > (real)1.0f || lambda < (real)0.0f) return -1;
  if (p == (real)0.0f) return 0;
  
  real term = exp(-lambda);
  real sum = term;
  int k = 0;
  real epsilon = (real)1e-7f; // Schützt vor GPU-Rundungsrauschen

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

// Interne RNG-Funktion (Knuth-Methode für kleine Lambda, Inversion für große Lambda)
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

// 🎯 Das Makro versteckt wieder die MT-Variablen
#define rpois(lambda) rpois_internal((lambda), &idx, mt)

// =========================================================================
// BINOMIAL DISTRIBUTION (Binomialverteilung)
// =========================================================================

// Wahrscheinlichkeitsfunktion (PMF / Dichte)
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

// Verteilungsfunktion (CDF)
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

// Quantilfunktion (Inverse CDF)
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

// Interne RNG-Funktion (Münzwurf-Methode für kleine n, Inversion für große n)
static inline int rbinom_internal(int n, real p, __private int* idx, __private uint* mt) {
  if (p < (real)0.0f || p > (real)1.0f || n < 0) return (real)NAN;
  
  int successes = 0;
  
  // Für kleine bis mittlere n simulieren wir direkt die Einzelversuche (Bernoulli)
  for (int i = 0; i < n; ++i) {
    if (mt_rand_01(idx, mt) <= p) {
      successes++;
    }
  }
  return successes;
}

// 🎯 Das Makro versteckt wieder die MT-Variablen für den Kernel-Aufruf
#define rbinom(size, prob) rbinom_internal((size), (prob), &idx, mt)

// =========================================================================
// EXPONENTIAL DISTRIBUTION (Exponentialverteilung)
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

// Interne RNG-Funktion (Inversionsmethode)
static inline real rexp_internal(real rate, __private int* idx, __private uint* mt) {
  if (rate <= (real)0.0f) return (real)NAN;
  // Da mt_rand_01 in [0,1) liegt, ist 1.0 - u in (0,1], was log() sicher gegen -Inf macht
  real u = mt_rand_01(idx, mt);
  return -log((real)1.0f - u) / rate;
}

// 🎯 Das Makro versteckt wieder die MT-Variablen für den Kernel-Aufruf
#define rexp(rate) rexp_internal((rate), &idx, mt)

// =========================================================================
// GEOMETRIC DISTRIBUTION (Geometrische Verteilung)
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

// Quantile function (Inverse CDF) - Exakt auf R-Parametrisierung abgestimmt
static inline int qgeom(real p, real prob) {
  if (p < (real)0.0f || p > (real)1.0f || prob <= (real)0.0f || prob > (real)1.0f) return -1;
  if (p == (real)0.0f) return 0;
  if (p == (real)1.0f) return 2147483647; // INT_MAX für p = 1
  if (prob == (real)1.0f) return 0;

  // 🌟 DER ORIGINALE R-CORE-ALGORITHMUS (Aus src/nmath/qgeom.c):
  // R nutzt: ceil(log(1 - p) / log(1 - prob) - 1e-7) - 1;
  // Das subtrahierte 1e-7 verhindert, dass exakte Ganzzahlgrenzen 
  // durch GPU-Bit-Ungenauigkeiten fälschlicherweise aufgerundet werden.
  
  real num = log((real)1.0f - p);
  real denom = log((real)1.0f - prob);
  
  int q = (int)ceil(num / denom - (real)1e-7) - 1;
  
  return q < 0 ? 0 : q;
}

// Internal RNG function (Inversion method via continuous exponential)
static inline int rgeom_internal(real prob, __private int* idx, __private uint* mt) {
  if (prob <= (real)0.0f || prob > (real)1.0f) return (real)NAN;
  if (prob == (real)1.0f) return (real)0.0f;
  
  real u = mt_rand_01(idx, mt);
  // floor(log(1-u) / log(1-prob)) simuliert exakt die Anzahl der Fehlschläge
  return (int)(floor(log((real)1.0f - u) / log((real)1.0f - prob)));
}

// 🎯 The macro hides the MT variables for the kernel call
#define rgeom(prob) rgeom_internal((prob), &idx, mt)


// =========================================================================
// NEGATIVE BINOMIAL DISTRIBUTION (Negative Binomialverteilung)
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
  
  // 1. Generate a Gamma variable Y ~ Gamma(shape=size, scale=(1-prob)/prob)
  // (Hinweis: Falls rgamma() in deiner libkernel noch fehlt, nutzen wir hier 
  // temporär die Inversions-Treppensuche oder setzen voraus, dass rgamma_internal existiert)
  // Da die vollständige Gamma-Generierung komplex ist, nutzen wir die bewährte Inversion für diskrete Werte:
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

// 🎯 The macro hides the MT variables for the kernel call
#define rnbinom(size, prob) rnbinom_internal((size), (prob), &idx, mt)

// =========================================================================
// HYPERGEOMETRIC DISTRIBUTION (Hypergeometrische Verteilung)
// =========================================================================

// Probability mass function (PMF)
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

// 🎯 The macro hides the MT variables for the kernel call
#define rhyper(m, n, k) rhyper_internal((m), (n), (k), &idx, mt)

// =========================================================================
// GAMMA DISTRIBUTION (Gamma-Verteilung)
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

// Cumulative Distribution Function (CDF) via unvollständige Gamma-Reihe oder Approximation
static inline real pgamma(real q, real shape, real rate) {
  if (shape <= (real)0.0f || rate <= (real)0.0f) return (real)0.0f;
  if (q <= (real)0.0f) return (real)0.0f;
  
  // Nutzt den skalierten Wert x = q * rate
  real x = q * rate;
  
  // Reihenentwicklung für das regulierte untere Gamma (P(a, x))
  real sum = (real)1.0f / shape;
  real term = sum;
  for (int i = 1; i < 100; ++i) {
    term *= x / (shape + (real)i);
    sum += term;
    if (term < sum * (real)1e-7f) break; // Präzisions-Guard
  }
  return sum * exp(-x + shape * log(x) - lgamma(shape));
}

// Quantile Function (Inverse CDF) per numerischer Newton-Raphson Verfeinerung
static inline real qgamma(real p, real shape, real rate) {
  if (p < (real)0.0f || p > (real)1.0f || shape <= (real)0.0f || rate <= (real)0.0f) return (real)NAN;
  if (p == (real)0.0f) return (real)0.0f;
  if (p == (real)1.0f) return (real)INFINITY;
  
  // Erste grobe Schätzung (Wilson-Hilferty Transformation)
  real d = (real)1.0f / ((real)9.0f * shape);
  real v = (real)1.0f - d + qnorm(p, (real)0.0f, (real)1.0f) * sqrt(d);
  real guess = shape * v * v * v / rate;
  if (guess < (real)0.0f) guess = (real)1e-5f;
  
  // Newton-Raphson Verfeinerungsschleife
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

  // 🛡️ REKURSIONSFREIER Ahrens-Dieter-Schritt für shape < 1
  if (d_shape < (real)1.0f) {
    real u = mt_rand_01(idx, mt);
    if (u <= (real)0.0f) u = (real)GPGPU_SAFE_MAX;
    adjustment = pow(u, (real)1.0f / d_shape);
    d_shape += (real)1.0f; // Schaltet auf die Marsaglia-Tsang Basis um
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
    
    // Guard gegen NaNs aus Box-Muller
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

// 🎯 The macro hides the MT variables for the kernel call
#define rgamma(shape, rate) rgamma_internal((shape), (rate), &idx, mt)

// =========================================================================
// WEIBULL DISTRIBUTION (Weibull-Verteilung)
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
  // Da u in [0,1) liegt, ist 1.0 - u in (0,1], absolut sicher für den Logarithmus
  return scale * pow(-log((real)1.0f - u), (real)1.0f / shape);
}

// 🎯 The macro hides the MT variables for the kernel call
#define rweibull(shape, scale) rweibull_internal((shape), (scale), &idx, mt)

// =========================================================================
// CHI-SQUARED DISTRIBUTION (Chi-Quadrat-Verteilung)
// =========================================================================

// Probability Density Function (PDF)
static inline real dchisq(real x, int df) {
  if (df <= 0) return (real)0.0f;
  // Chi-squared(df) ist identisch zu Gamma(shape = df/2, rate = 0.5)
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

// 🎯 The macro hides the MT variables for the kernel call
#define rchisq(df) rchisq_internal((df), &idx, mt)


///// 1111
// =========================================================================
// BETA DISTRIBUTION & STUDENT-T DISTRIBUTION (Stabilized via Continued Fractions)
// =========================================================================

// Regularized Incomplete Beta Function I_x(a, b) via Lentz's Continued Fraction Method
static inline real core_incomplete_beta(real x, real a, real b) {
    if (x <= (real)0.0f) return (real)0.0f;
    if (x >= (real)1.0f) return (real)1.0f;
    if (isnan(x) || isnan(a) || isnan(b)) return (real)NAN;

    real log_beta_const = lgamma(a + b) - (lgamma(a) + lgamma(b));
    real front = exp(log_beta_const + a * log(x) + b * log((real)1.0f - x));

    if (x > (a + (real)1.0f) / (a + b + (real)2.0f)) {
        return (real)1.0f - core_incomplete_beta((real)1.0f - x, b, a);
    }

    real qab = a + b;
    real qap = a + (real)1.0f;
    real qam = a - (real)1.0f;
    real c = (real)1.0f;
    real d = (real)1.0f - qab * x / qap;
    if (fabs(d) < (real)1e-30f) d = (real)1e-30f;
    d = (real)1.0f / d;
    real f = d;

    // 🛡️ Harter Schutz gegen GPU-Freeze: m MUSS terminieren
    for (int m = 1; m <= 100; ++m) {
        real m_real = (real)m;
        real m2 = (real)2.0f * m_real;
        
        real aa = m_real * (b - m_real) * x / ((qam + m2) * (a + m2));
        
        // Verhindere NaN/Inf Explosionen in der Kette
        if (isnan(aa) || isinf(aa)) return (real)0.0f;

        d = (real)1.0f + aa * d;
        if (fabs(d) < (real)1e-30f) d = (real)1e-30f;
        c = (real)1.0f + aa / c;
        if (fabs(c) < (real)1e-30f) c = (real)1e-30f;
        d = (real)1.0f / d;
        real delta = d * c;
        f *= delta;

        aa = -(a + m_real) * (qab + m_real) * x / ((a + m2) * (qap + m2));
        if (isnan(aa) || isinf(aa)) return (real)0.0f;

        d = (real)1.0f + aa * d;
        if (fabs(d) < (real)1e-30f) d = (real)1e-30f;
        c = (real)1.0f + aa / c;
        if (fabs(c) < (real)1e-30f) c = (real)1e-30f;
        d = (real)1.0f / d;
        delta = d * c;
        f *= delta;

        if (fabs(delta - (real)1.0f) < (real)1e-7f) {
            break;
        }
    }

    real result = front * f / a;
    if (isnan(result) || isinf(result)) return (real)0.0f;
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

// Cumulative Distribution Function (CDF) via stabilen Kettenbruch
static inline real pbeta(real q, real shape1, real shape2) {
  return core_incomplete_beta(q, shape1, shape2);
}

// Quantile Function (Inverse CDF) per Newton-Raphson Verfeinerung
static inline real qbeta(real p, real shape1, real shape2) {
  if (p < (real)0.0f || p > (real)1.0f || shape1 <= (real)0.0f || shape2 <= (real)0.0f) return (real)NAN;
  if (p == (real)0.0f) return (real)0.0f;
  if (p == (real)1.0f) return (real)1.0f;
  
  real a = shape1;
  real b = shape2;
  real mean = a / (a + b);
  real guess = mean;
  
  for (int i = 0; i < 15; ++i) {
    real error = pbeta(guess, a, b) - p;
    if (fabs(error) < (real)1e-5f) break;
    real deriv = dbeta(guess, a, b);
    if (deriv == (real)0.0f) break;
    guess -= error / deriv;
    if (guess <= (real)0.0f) guess = (real)1e-5f;
    if (guess >= (real)1.0f) guess = (real)0.99999f;
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

// Student-t Cumulative Distribution Function (CDF) über unvollständige Beta-Identität
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
// F DISTRIBUTION (F-Verteilung)
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

// Cumulative Distribution Function (CDF) via Rückgriff auf die Beta-Verteilung
static inline real pf(real q, int df1, int df2) {
  if (df1 <= 0 || df2 <= 0) return (real)0.0f;
  if (q <= (real)0.0f) return (real)0.0f;
  real d1 = (real)df1;
  real d2 = (real)df2;
  real x = (d1 * q) / (d1 * q + d2);
  return pbeta(x, d1 * (real)0.5f, d2 * (real)0.5f);
}

// Quantile Function (Inverse CDF) per Newton-Raphson Verfeinerung
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
// LOG-NORMAL DISTRIBUTION (Log-Normalverteilung)
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
  
  // Standardnormalverteiltes Paar generieren (Box-Muller)
  real u1 = mt_rand_01(idx, mt);
  real u2 = mt_rand_01(idx, mt);
  real z = sqrt((real)-2.0f * log(u1)) * cos((real)2.0f * (real)M_PI * u2);
  
  // Transformieren zu log-normal
  real y = meanlog + sdlog * z;
  return exp(y);
}

// 🎯 The macro hides the MT variables for the kernel call
#define rlnorm(meanlog, sdlog) rlnorm_internal((meanlog), (sdlog), &idx, mt)

// =========================================================================
// CAUCHY DISTRIBUTION (Cauchy-Verteilung)
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
  // Da mt_rand_01 im Intervall [0, 1) liegt, ist das mathematisch absolut stabil
  return location + scale * tan((real)M_PI * (u - (real)0.5f));
}

// 🎯 The macro hides the MT variables for the kernel call
#define rcauchy(location, scale) rcauchy_internal((location), (scale), &idx, mt)

// =========================================================================
// LOGISTIC DISTRIBUTION (Logistische Verteilung)
// =========================================================================

// Probability Density Function (PDF)
static inline real dlogis(real x, real location, real scale) {
  if (scale <= (real)0.0f) return (real)0.0f;
  real z = (x - location) / scale;
  // Vermeidung von numerischen Overflows bei extremen z-Werten
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
  // Da u in [0, 1) liegt, ist 1-u > 0, log() ist sicher vor -Inf Fehlern geschützt
  if (u == (real)0.0f) u = (real)1e-7f; 
  return location + scale * log(u / ((real)1.0f - u));
}

// 🎯 The macro hides the MT variables for the kernel call
#define rlogis(location, scale) rlogis_internal((location), (scale), &idx, mt)


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

// 🛡️ wls_gls_fit STEHT JETZT KORREKT VOR ls_poly_fit!
static inline int wls_gls_fit(const real *A_in, const real *b_in, int m, int n, 
                              const real *Sigma, const real *weights, real *x_out,
                              real *workspace_A_tilde, real *workspace_b_tilde,
                              real *workspace_L, real *workspace_col,
                              real *workspace_R, real *workspace_qty) {
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
