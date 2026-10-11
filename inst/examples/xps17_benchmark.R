# ==============================================================================
# 🚀 ULTRA-BENCHMARK V3: XPS 17 MIT TOTALER COLDSTART-ELIMINIERUNG (Rcpp & OpenCL)
# ==============================================================================
library(parallel)
library(Rcpp)
library(RcppParallel)
library(OpenCLeaR)

# Gesterige CPU- und Rcpp-Triebwerke einbinden
#source("mh_r.R")
#source("mh_rcpp.R")
#source("mh_ocl.R")

# ==============================================================================
# 🎯 BENCHMARK-PARAMETER (Exakt wie gestern)
# ==============================================================================
samples <- 1000000L    
nchains <- 10000L       
samples_per_chain <- as.integer(samples / nchains)

set.seed(444)
data <- rnorm(1000, mean = 5, sd = 2)
mu_obs    <- mean(data)
sigma_obs <- sd(data)

r_seed <- get(".Random.seed", envir = .GlobalEnv)
base_seed <- as.integer(r_seed[2])
# Mini-Parameter für die plattformweite Warm-up-Phase
warm_samples <- 1000L
warm_chains <- 10L
warm_samples_per_chain <- as.integer(warm_samples / warm_chains)

cat("\n🔥 --- INITIERE COLDSTART-KILLER FÜR ALLE CPU/RCPP TRIEBWERKE --- 🔥\n")

# 1. Warm-up: Reines R
invisible(run_mh_pure_r(warm_samples_per_chain, warm_chains, data, mu_obs, sigma_obs, base_seed))

# 2. Warm-up: mclapply Subprozesse (Triggert das Forking/Prozess-Caching von Linux/macOS/WSL)
tryCatch({
  invisible(run_mh_r_subprocesses(warm_samples_per_chain, warm_chains, data, mu_obs, sigma_obs, base_seed))
}, error = function(e) {})

# 3. Warm-up: Rcpp Serial (Eliminiert CXX-Inline Symbol-Lookup und initialisiert Cache)
invisible(run_mh_rcpp_serial(warm_samples, warm_chains, data, mu_obs, sigma_obs, base_seed))

# 4. Warm-up: RcppParallel TBB (Initialisiert den Intel TBB Thread-Pool im Hintergrund!)
invisible(run_mh_rcpp_parallel(warm_samples, warm_chains, data, mu_obs, sigma_obs, base_seed))

cat("🎉 Alle CPU- und Rcpp-Triebwerke sind warmgelaufen und im RAM geprimed!\n")


# ==============================================================================
# 🛠️ ERWEITERTE HILFSFUNKTION FÜR OPENCLEAR (Mit JIT-Warm-up)
# ==============================================================================
run_openclear_stage <- function(device_id, force_float, label) {
  cat("\n--------------------------------------------------------------------------\n")
  cat(sprintf("🎬 INITIALISIERE STAGE: Device %d (%s)\n", device_id, label))
  cat("--------------------------------------------------------------------------\n")
  
  # 1. Device aktivieren
  ActivateDeviceWithIndex(device_id)
  
  # 2. Sofort danach Device-Informationen ausgeben
  cat(sprintf("[HARDWARE INFO] Aktives Profil für Device %d:\n", device_id))
  tryCatch({
    print(GetActiveDeviceInfo())
  }, error = function(e) {
    cat("⚠️ getDeviceInfo() konnte nicht ausgelesen werden:", e$message, "\n")
  })
  
  # 3. Präzisions-Modus umschalten
  if (exists("setForceFloat", envir = asNamespace("OpenCLeaR"))) {
    setForceFloat(force_float)
    cat(sprintf("-> Präzisions-Flag gesetzt auf: force_float = %s\n", as.character(force_float)))
  }
  
  # 4. OpenCL JIT-Compiler Warm-up (Triggert OpenCL JIT Code-Gen für dieses spezifische Device)
  cat("⏳ OpenCL JIT-Compiler triggern (Warm-up-Lauf ohne Messung)... ")
  tryCatch({
    invisible(parallel_MH_sampler(as.integer(warm_samples), as.integer(warm_chains), data, mu_obs, sigma_obs))
    cat("Done. OpenCL Kernel ist kompiliert!\n")
  }, error = function(e) {
    cat("Fehler beim OpenCL Warm-up:", e$message, "\n")
  })
  
  # 5. Echte Zeitmessung des optimierten Samplers starten
  cat("⏱️ Starte echten Messdurchlauf (1.000.000 Samples)...\n")
  t_start <- Sys.time()
  
  res_gpu <- parallel_MH_sampler(as.integer(samples), as.integer(nchains), data, mu_obs, sigma_obs)
  
  t_end <- Sys.time()
  duration <- as.numeric(difftime(t_end, t_start, units = "secs"))
  
  cat(sprintf("-> Stage beendet. Reine Rechenzeit: %.4f Sekunden.\n", duration))
  return(duration)
}

# ==============================================================================
# 🏁 DER ULTRA-BENCHMARK-ABLAUF (100% REINE hardware-RECHENZEIT)
# ==============================================================================
cat("\n🏁 --- STARTE PLATTFORM-ÜBERGREIFENDEN ULTRA-BENCHMARK (XPS 17 PROFIL) --- 🏁\n")

# --- 1. Die klassischen CPU-Gegner (Jetzt absolut unverfälscht) ---
cat("\n⏳ [CPU] 1. Berechne reines R-Skript (1 CPU Kern)...\n")
t_start_r  <- Sys.time()
res_r      <- run_mh_pure_r(samples_per_chain, nchains, data, mu_obs, sigma_obs, base_seed)
time_r     <- as.numeric(difftime(Sys.time(), t_start_r, units = "secs"))

cat("\n⏳ [CPU] 2. Berechne R-Parallel-Subprozesse (mclapply)......\n")
time_mcl   <- tryCatch({
  t_start_mcl <- Sys.time()
  res_mcl     <- run_mh_r_subprocesses(samples_per_chain, nchains, data, mu_obs, sigma_obs, base_seed)
  as.numeric(difftime(Sys.time(), t_start_mcl, units = "secs"))
}, error = function(e) { NA })

cat("\n⏳ [CPU] 3. Berechne serielles Rcpp (1 CPU Kern)...\n")
t_start_serial <- Sys.time()
res_serial     <- run_mh_rcpp_serial(samples, nchains, data, mu_obs, sigma_obs, base_seed)
time_serial    <- as.numeric(difftime(Sys.time(), t_start_serial, units = "secs"))

cat("\n⏳ [CPU] 4. Berechne RcppParallel TBB (Alle CPU Threads)...\n")
t_start_tbb  <- Sys.time()
res_tbb      <- run_mh_rcpp_parallel(samples, nchains, data, mu_obs, sigma_obs, base_seed)
time_tbb     <- as.numeric(difftime(Sys.time(), t_start_tbb, units = "secs"))


# --- 2. Die OpenCLeaR GPGPU Pipeline mit Hardware-Präzisions-Matrix ---
# Dev 0: NVIDIA GPU (Normal / Double)
time_oc_nv_double <- tryCatch({
  run_openclear_stage(device_id = 0, force_float = FALSE, label = "NVIDIA GPU Normal")
}, error = function(e) { NA })

# Dev 0: NVIDIA GPU (Force Float)
#time_oc_nv_float <- tryCatch({
#  run_openclear_stage(device_id = 0, force_float = TRUE, label = "NVIDIA GPU Force Float")
#}, error = function(e) { NA })

# Dev 1: Intel iGPU (Normal -> Rechnet laut Vorgabe direkt als Float)
time_oc_intel_gpu_float <- tryCatch({
  run_openclear_stage(device_id = 1, force_float = FALSE, label = "Intel iGPU Normal")
}, error = function(e) { NA })

# Dev 2: Intel i9 CPU via OpenCL (Normal / Double)
#time_oc_cpu_double <- tryCatch({
#  run_openclear_stage(device_id = 2, force_float = FALSE, label = "Intel i9 OpenCL Normal")
#}, error = function(e) { NA })

# Dev 2: Intel i9 CPU via OpenCL (Force Float)
#time_oc_cpu_float <- tryCatch({
#  run_openclear_stage(device_id = 2, force_float = TRUE, label = "Intel i9 OpenCL Force Float")
#}, error = function(e) { NA })


# ==============================================================================
# 📊 --- FINALER REPORT ---
# ==============================================================================
cat("\n📊 ================== FINALER XPS 17 CORES VS. GPGPU VERGLEICH ==================\n")

format_row <- function(name, mode, time_val, base_time) {
  if (is.na(time_val)) return(sprintf(" %-40s | %-8s | %-10s | %-12s\n", name, mode, "CRASH/NA", "-"))
  speedup <- if (time_val > 0) round(base_time / time_val, 2) else 0
  return(sprintf(" %-40s | %-8s | %-9.4fs | %.2fx\n", name, mode, time_val, speedup))
}

cat(sprintf(" %-40s | %-8s | %-10s | %-12s\n", "Architektur / Triebwerk", "Modus", "Laufzeit", "Beschleunigung"))
cat(paste0(rep("-", 82), collapse = ""), "\n")

cat(format_row("🔴 Reines R-Skript (1 Core)", "Double", time_r, time_r))
cat(format_row("🟤 R-Subprozesse (mclapply Multi)", "Double", time_mcl, time_r))
cat(format_row("🟠 Nativer C++ Kern (1 Thread)", "Double", time_serial, time_r))
cat(format_row("🟡 RcppParallel TBB (CPU Threads)", "Double", time_tbb, time_r))

cat(paste0(rep("-", 82), collapse = ""), "\n")
cat(" 🟢 OpenCLeaR GPGPU Triebwerke (Reine Rechenzeit nach JIT- & CXX-Kompilierung):\n")
cat(paste0(rep("-", 82), collapse = ""), "\n")

cat(format_row("   ↳ Device 0: NVIDIA GPU - Normal", "Double", time_oc_nv_double, time_r))
#cat(format_row("   ↳ Device 0: NVIDIA GPU - Forced", "Float",  time_oc_nv_float, time_r))
cat(format_row("   ↳ Device 1: Intel iGPU - Normal", "Float",  time_oc_intel_gpu_float, time_r))
#cat(format_row("   ↳ Device 2: Intel i9 CPU - Normal", "Double", time_oc_cpu_double, time_r))
#cat(format_row("   ↳ Device 2: Intel i9 CPU - Forced", "Float",  time_oc_cpu_float, time_r))

cat("==================================================================================\n")
