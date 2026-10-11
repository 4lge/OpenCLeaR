# ==============================================================================
# 🚀 ISOLATED RUNNER FOR XPS 17 BENCHMARK (ANTI-MEMORY CORRUPTION)
# ==============================================================================
args <- commandArgs(trailingOnly = TRUE)
stage <- if(length(args) > 0) as.integer(args[1]) else 0 # Standard: Device 0 Normal

library(parallel)
library(Rcpp)
library(RcppParallel)
library(inline)
library(OpenCLeaR)

# Triebwerke frisch laden
source("OpenCLeaR/inst/examples/mh_r.R")
source("OpenCLeaR/inst/examples/mh_rcpp.R")
source("OpenCLeaR/inst/examples/mh_ocl.R")

# Parameter
samples <- 1000000L    
nchains <- 10000L       
samples_per_chain <- as.integer(samples / nchains)

set.seed(444)
data <- rnorm(1000, mean = 5, sd = 2)
mu_obs    <- mean(data)
sigma_obs <- sd(data)
base_seed <- as.integer(get(".Random.seed", envir = .GlobalEnv)[2])

# Warm-up Parameter gegen Grid-Crashes
warm_chains  <- 10000L
warm_samples_per_chain <- 1L
warm_samples <- as.integer(warm_chains * warm_samples_per_chain)

# Mappe die Stages auf (Device, Force_Float, Label)
configs <- list(
  `0` = list(id = 0, ff = FALSE, label = "NVIDIA GPU - Normal (Double)"),
  `1` = list(id = 0, ff = TRUE,  label = "NVIDIA GPU - Forced (Float)"),
  `2` = list(id = 1, ff = FALSE, label = "Intel iGPU - Normal (Float)"),
  `3` = list(id = 2, ff = FALSE, label = "Intel i9 CPU - Normal (Double)"),
  `4` = list(id = 2, ff = TRUE,  label = "Intel i9 CPU - Forced (Float)")
)

cfg <- configs[[as.character(stage)]]

cat(sprintf("\n🎬 STARTING ISOLATED STAGE: %s\n", cfg$label))
ActivateDeviceWithIndex(cfg$id)

tryCatch({ print(GetActviveDeviceInfo()) }, error = function(e) {})

if (exists("setForceFloat", envir = asNamespace("OpenCLeaR"))) {
  setForceFloat(cfg$ff)
}

# Warm-up (Kompilierung)
invisible(parallel_MH_sampler(as.integer(warm_samples), as.integer(warm_chains), data, mu_obs, sigma_obs))

# Echte Zeitmessung
t_start <- Sys.time()
res_gpu <- parallel_MH_sampler(as.integer(samples), as.integer(nchains), data, mu_obs, sigma_obs)
duration <- as.numeric(difftime(Sys.time(), t_start, units = "secs"))

# Speichere das Ergebnis kurz in einer temporären Datei ab für den finalen Report
writeLines(sprintf("%d;%s;%.4f", stage, cfg$label, duration), sprintf("stage_%d.res", stage))
cat(sprintf("⏱️ Zeit fuer %s: %.4f Sekunden.\n", cfg$label, duration))
