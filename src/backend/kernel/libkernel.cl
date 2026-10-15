// -*- c -*-

// 🛡️ DYNAMISCHE STRATEGISCHE ARCHITEKTUR-SCHRÄNKEN
#if defined(cl_khr_fp64) || defined(cl_amd_fp64)
#define GPGPU_EPSILON 1e-16
#define GPGPU_SAFE_MAX 1e-300
#else
#define GPGPU_EPSILON 1e-6f
#define GPGPU_SAFE_MAX 1e-37f
#endif
// use: (X.Xf * GPGPU_EPSILON)

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
    while(u1 <= 1e-7f) u1 = mt_rand_01(&mt[0], &idx[0], mt); // underflow
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
#include <math.h>
#include <stdlib.h>

int core_qr_ls_solve(const double *A_in, const double *b_in, int m, int n, double *x) {
    if (m < n || !A_in || !b_in || !x) return -1;

    double *R = (double *)malloc(m * n * sizeof(double));
    double *qty = (double *)malloc(m * sizeof(double));
    if (!R || !qty) { free(R); free(qty); return -1; }

    for (int i = 0; i < m * n; i++) R[i] = A_in[i];
    for (int i = 0; i < m; i++) qty[i] = b_in[i];

    for (int k = 0; k < n; k++) {
        double nrm2 = 0.0;
        for (int i = k; i < m; i++) nrm2 += R[i * n + k] * R[i * n + k];
        double norm = sqrt(nrm2);
        
        if (norm < GPGPU_EPSILON) { free(R); free(qty); return -1; }

        double ak = R[k * n + k];
        double alpha = (ak > 0.0) ? -norm : norm;
        double u1 = ak - alpha;
        
        // ABSICHERUNG: u1 darf nicht numerisch verschwinden
        if (fabs(u1) < GPGPU_EPSILON) continue; 

        R[k * n + k] = alpha;

        // ABSICHERUNG: Nenner für beta gegen Null-Division schützen
        double denom = alpha * u1;
        if (fabs(denom) < GPGPU_EPSILON) denom = (denom < 0) ? -GPGPU_EPSILON : GPGPU_EPSILON;

        for (int j = k + 1; j < n; j++) {
            double dot = R[k * n + j];
            for (int i = k + 1; i < m; i++) {
                dot += (R[i * n + k] / u1) * R[i * n + j];
            }
            double beta = dot / denom;
            
            R[k * n + j] -= beta * u1;
            for (int i = k + 1; i < m; i++) R[i * n + j] -= beta * R[i * n + k];
        }

        double dot_b = qty[k];
        for (int i = k + 1; i < m; i++) {
            dot_b += (R[i * n + k] / u1) * qty[i];
        }
        double beta_b = dot_b / denom;
        
        qty[k] -= beta_b * u1;
        for (int i = k + 1; i < m; i++) qty[i] -= beta_b * R[i * n + k];
    }

    // Rückwärtssubstitution absichern
    for (int i = n - 1; i >= 0; i--) {
        double sum = qty[i];
        for (int j = i + 1; j < n; j++) sum -= R[i * n + j] * x[j];
        
        // ABSICHERUNG: Nenner-Check auf der Diagonale
        if (fabs(R[i * n + i]) < GPGPU_EPSILON) { free(R); free(qty); return -1; }
        x[i] = sum / R[i * n + i];
    }

    free(R); free(qty);
    return 0;
}


/**
 * Generiert eine numerisch stabile, normierte polynomielle Design-Matrix.
 * Schützt vor exponentiellem Unterlauf/Überlauf auf GPGPU-Architekturen.
 *
 * @param x_data      Rohdaten der x-Koordinaten (Größe m).
 * @param m           Anzahl der Messpunkte.
 * @param degree      Polynomgrad (n = degree + 1).
 * @param A_out       Zielpuffer der Größe m * (degree + 1).
 * @param x_min_out   Rückgabewert für das Minimum (wichtig für die spätere Auswertung des Fits!).
 * @param x_scale_out Rückgabewert für den Skalierungsfaktor (wichtig für spätere Auswertung!).
 */
static inline int generate_poly_design_matrix_safe(const double *x_data, int m, int degree, double *A_out,
                                     double *x_min_out, double *x_scale_out) {
    if (!x_data || !A_out || m <= 0 || degree < 0 || !x_min_out || !x_scale_out) return -1;
    
    int n = degree + 1;

    // 1. Extremwerte finden für die Skalierung (Min-Max-Normierung auf [0, 1] oder [-1, 1])
    double min_x = x_data[0];
    double max_x = x_data[0];
    for (int i = 1; i < m; i++) {
        if (x_data[i] < min_x) min_x = x_data[i];
        if (x_data[i] > max_x) max_x = x_data[i];
    }

    double range = max_x - min_x;
    
    // ABSICHERUNG: Wenn alle X-Werte (nahezu) identisch sind, ist keine Polynom-Regression möglich
    if (fabs(range) < GPGPU_EPSILON) {
        range = GPGPU_EPSILON; // Verhindert Division durch 0 bei der Skalierung
    }

    // Werte für die spätere Rücktransformation von x_fit sichern
    *x_min_out = min_x;
    *x_scale_out = range;

    // 2. Matrix zeilenweise stabil befüllen
    for (int i = 0; i < m; i++) {
        // Feature Scaling: x_norm liegt sauber im Intervall [0.0, 1.0]
        // Dadurch bleibt jede Potenz x^j streng im Bereich [0.0, 1.0] und kann NIEMALS überlaufen!
        double x_norm = (x_data[i] - min_x) / range;
        
        A_out[i * n + 0] = 1.0; // x^0
        
        for (int j = 1; j < n; j++) {
            double val = A_out[i * n + (j - 1)] * x_norm;
            
            // ABSICHERUNG gegen schleichenden Unterlauf (Subnormale Zahlen verhindern)
            if (fabs(val) < GPGPU_EPSILON) {
                val = 0.0; 
            }
            A_out[i * n + j] = val;
        }
    }
    
    return 0;
}

/**
 * Rechnet die Koeffizienten eines normierten Polynom-Fits auf die Originalskala zurück.
 * Transformiert das Modell von c * [(x - x_min)/x_scale]^j  zurück zu  a * x^k.
 *
 * @param c_norm     Die vom Solver berechneten Koeffizienten des skalierten Systems. Größe: degree + 1.
 * @param degree     Der Grad des Polynoms.
 * @param x_min      Das aus generate_poly_design_matrix_safe stammende x_min.
 * @param x_scale    Der aus generate_poly_design_matrix_safe stammende x_scale Faktor.
 * @param a_orig     Zielpuffer der Größe degree + 1 für die unskalierten Originalkoeffizienten.
 * @return           0 bei Erfolg, -1 bei Fehlern.
 */
int restore_original_coefficients(const double *c_norm, int degree, double x_min, double x_scale, double *a_orig) {
    if (!c_norm || !a_orig || degree < 0) return -1;
    if (fabs(x_scale) < GPGPU_EPSILON) return -1; // Sicherheitscheck gegen Division durch 0

    int n = degree + 1;
    memset(a_orig, 0, n * sizeof(double));

    // Kombinatorischer Workspace für Binomialkoeffizienten n über k
    // Speicherbedarf ist minimal: (degree + 1) * (degree + 1)
    double *binom = (double *)malloc(n * n * sizeof(double));
    if (!binom) return -1;
    memset(binom, 0, n * n * sizeof(double));

    // 1. Pascalsches Dreieck im Speicher aufbauen
    for (int i = 0; i < n; i++) {
        binom[i * n + 0] = 1.0;
        for (int j = 1; j <= i; j++) {
            binom[i * n + j] = binom[(i - 1) * n + (j - 1)] + binom[(i - 1) * n + j];
        }
    }

    // 2. Rücktransformation über Polynom-Expansion
    // Wir akkumulieren die Beiträge jedes skalierten Terms c_j * (x/scale - min/scale)^j
    for (int j = 0; j < n; j++) {
        double c_val = c_norm[j];
        if (fabs(c_val) < GPGPU_EPSILON) continue; // Numerischer Skip für fast-null Koeffizienten

        // Faktor 1 / (x_scale^j)
        double inv_scale_pow = 1.0 / pow(x_scale, j);
        
        // Expansion von (x - x_min)^j mittels Binomischem Lehrsatz
        for (int k = 0; k <= j; k++) {
            double b_coeff = binom[j * n + k];
            double min_pow = pow(-x_min, j - k);
            
            // Absicherung gegen subnormale Unterläufe bei extremen Potenzen
            double term = c_val * inv_scale_pow * b_coeff * min_pow;
            if (fabs(term) < GPGPU_EPSILON) {
                term = 0.0;
            }

            // Der k-te Term der Expansion trägt zum k-ten globalen Koeffizienten bei
            a_orig[k] += term;
        }
    }

    free(binom);
    return 0;
}

/**
 * Berechnet die Cholesky-Faktorisierung einer symmetrisch positiv-definiten 
 * Kovarianzmatrix Sigma = L * L^T.
 * @param Sigma  Symmetrische m x m Kovarianzmatrix (Row-Major).
 * @param m      Dimension der Matrix (Anzahl der Messpunkte).
 * @param L      Zielpuffer für die untere Dreiecksmatrix L (Größe m x m).
 * @return       0 bei Erfolg, -1 wenn die Matrix nicht positiv-definitiv ist.
 */
static implicit int core_cholesky(const double *Sigma, int m, double *L) {
    memset(L, 0, m * m * sizeof(double));
    for (int i = 0; i < m; i++) {
        for (int j = 0; j <= i; j++) {
            double sum = Sigma[i * m + j];
            for (int k = 0; k < j; k++) {
                sum -= L[i * m + k] * L[j * m + k];
            }
            if (i == j) {
                if (sum <= GPGPU_EPSILON) return -1; // Nicht positiv-definit
                L[i * m + j] = sqrt(sum);
            } else {
                L[i * m + j] = sum / L[j * m + j];
            }
        }
    }
    return 0;
}

/**
 * Führt das "Whitening" durch (Löst L * tilde = original via Vorwärtssubstitution).
 * Transformiert entweder eine Spalte der Designmatrix oder den Vektor b.
 */
static implicit void core_forward_substitute(const double *L, int m, const double *input, double *output) {
    for (int i = 0; i < m; i++) {
        double sum = input[i];
        for (int j = 0; j < i; j++) {
            sum -= L[i * m + j] * output[j];
        }
        output[i] = sum / L[i * m + i];
    }
}
/**
 * High-Level Kapselung für die polynomielle Ausgleichsrechnung (Ordinary Least Squares).
 * Isoliert die interne GPGPU-Skalierung komplett vom Aufrufer.
 *
 * @param x_data Spaltenvektor der x-Koordinaten (Größe m).
 * @param y_data Spaltenvektor der y-Koordinaten (Rechte Seite / Messwerte, Größe m).
 * @param m      Anzahl der Messpunkte (m >= degree + 1).
 * @param degree Der gewünschte Grad des Polynoms (z.B. 2 für Parabel).
 * @param a_out  Ziel-Array der Größe (degree + 1). Enthält am Ende die echten, 
 *               unskalierten Koeffizienten [a0, a1, a2, ... ad] für: y = a0 + a1*x + a2*x^2 + ...
 * @return       0 bei Erfolg, -1 bei Fehlern (z.B. Rangmangel, Speicher).
 */
int ls_poly_fit(const double *x_data, const double *y_data, int m, int degree, double *a_out) {
    if (!x_data || !y_data || !a_out || degree < 0 || m < (degree + 1)) {
        return -1;
    }

    int n = degree + 1; // Anzahl der Koeffizienten

    // 1. Temporären Workspace für die Design-Matrix und normierte Koeffizienten allozieren
    double *A_design = (double *)malloc(m * n * sizeof(double));
    double *c_norm = (double *)malloc(n * sizeof(double));
    if (!A_design || !c_norm) {
        free(A_design); free(c_norm);
        return -1;
    }

    // Variablen für die Skalierungsparameter
    double x_min = 0.0;
    double x_scale = 1.0;

    // 2. Schritt: Numerisch stabile Design-Matrix im Intervall [0, 1] generieren
    if (generate_poly_design_matrix_safe(x_data, m, degree, A_design, &x_min, &x_scale) != 0) {
        free(A_design); free(c_norm);
        return -1;
    }

    // 3. Schritt: Das System über QR-Zerlegung lösen
    // Da wir hier reines OLS rechnen, übergeben wir für Sigma und weights jeweils NULL
    if (wls_gls_fit(A_design, y_data, m, n, NULL, NULL, c_norm) != 0) {
        free(A_design); free(c_norm);
        return -1;
    }

    // 4. Schritt: Rücktransformation der normierten Koeffizienten auf die Originalskala
    if (restore_original_coefficients(c_norm, degree, x_min, x_scale, a_out) != 0) {
        free(A_design); free(c_norm);
        return -1;
    }

    // Workspace aufräumen
    free(A_design);
    free(c_norm);
    return 0; // Erfolg!
}

/**
 * Führt einen verallgemeinerten (GLS) oder gewichteten (WLS) Least-Squares-Fit aus.
 * Geeignet für räumlich korrelierte Daten (Spatial Autocorrelation).
 *
 * @param A_in    Unkorrigierte Design-Matrix (m x n), z.B. aus dem Generator.
 * @param b_in    Unkorrigierter Messvektor (Größe m).
 * @param m       Anzahl der Messpunkte (Zeilen).
 * @param n       Anzahl der Parameter (Spalten).
 * @param Sigma   m x m Kovarianzmatrix für GLS (räumliche Korrelation). 
 *                Darf NULL sein, falls reines WLS gewünscht ist.
 * @param weights Vektor der Größe m mit inversen Varianzen (WLS). 
 *                Wird ignoriert, wenn Sigma gesetzt ist. Darf NULL sein (dann Standard-LS).
 * @param x_out   Zielpuffer für die berechneten Parameter (Größe n).
 * @return        0 bei Erfolg, -1 bei Fehlern (z.B. Singularität, Speicher).
 */
static implicit int wls_gls_fit(const double *A_in, const double *b_in, int m, int n, 
                const double *Sigma, const double *weights, double *x_out) {
    if (m < n || !A_in || !b_in || !x_out) return -1;

    // Temporäre Arbeitsmatrizen allozieren (Thread-lokal auf dem Heap)
    double *A_tilde = (double *)malloc(m * n * sizeof(double));
    double *b_tilde = (double *)malloc(m * sizeof(double));
    if (!A_tilde || !b_tilde) {
        free(A_tilde); free(b_tilde);
        return -1;
    }

    // FALL 1: Generalized Least Squares (GLS) für räumliche Abhängigkeiten
    if (Sigma != NULL) {
        double *L = (double *)malloc(m * m * sizeof(double));
        if (!L || core_cholesky(Sigma, m, L) != 0) {
            free(L); free(A_tilde); free(b_tilde);
            return -1; // Matrix nicht positiv-definit oder Speicher voll
        }

        // 1. Rechtesystem transformieren: L * b_tilde = b
        core_forward_substitute(L, m, b_in, b_tilde);

        // 2. Designmatrix spaltenweise transformieren: L * A_tilde_col = A_col
        double *col_in = (double *)malloc(m * sizeof(double));
        double *col_out = (double *)malloc(m * sizeof(double));
        
        for (int j = 0; j < n; j++) {
            for (int i = 0; i < m; i++) col_in[i] = A_in[i * n + j];
            
            core_forward_substitute(L, m, col_in, col_out);
            
            for (int i = 0; i < m; i++) A_tilde[i * n + j] = col_out[i];
        }
        
        free(col_in); free(col_out); free(L);
    }
    // FALL 2: Weighted Least Squares (WLS) via diagonale Gewichte (W = diag(weights))
    else if (weights != NULL) {
        for (int i = 0; i < m; i++) {
            double w_sqrt = sqrt(weights[i]); // Transformation via Wurzel des Gewichts
            b_tilde[i] = b_in[i] * w_sqrt;
            for (int j = 0; j < n; j++) {
                A_tilde[i * n + j] = A_in[i * n + j] * w_sqrt;
            }
        }
    }
    // FALL 3: Standard Ordinary Least Squares (OLS) Backup
    else {
        memcpy(A_tilde, A_in, m * n * sizeof(double));
        memcpy(b_tilde, b_in, m * sizeof(double));
    }

    // 3. Transformiertes, unkorreliertes System stabil per QR lösen
    // (Verweist auf die im vorherigen Schritt definierte core_qr_ls_solve)
    int status = core_qr_ls_solve(A_tilde, b_tilde, m, n, x_out);

    free(A_tilde);
    free(b_tilde);
    return status;
}
