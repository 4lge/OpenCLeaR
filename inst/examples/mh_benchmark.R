library(parallel)

# Skripte dynamisch hereinladen
#source("mh_r.R")
#source("mh_rcpp.R")

# ==============================================================================
# 🎯 PARAMETER FÜR DEN VIERKAMPF (Skaliert auf 100k, reißfest für R)
# ==============================================================================
samples <- 1000000L    
nchains <- 10000L       
samples_per_chain <- as.integer(samples / nchains)

set.seed(444)
data <- rnorm(1000, mean = 5, sd = 2)
mu_obs    <- mean(data)
sigma_obs <- sd(data)

# Base Seed absolut crash-frei aus R extrahieren!
r_seed <- get(".Random.seed", envir = .GlobalEnv)
base_seed <- as.integer(r_seed[2]) # Nutzt den absolut stabilen Index 2

cat("\n🏁 --- STARTE PLATTFORM-ÜBERGREIFENDEN ULTRA-BENCHMARK (100k Punkte) --- 🏁\n")

# 1. Reiner R-Lauf (Seriell)
cat("⏳ 1. Berechne reines R-Skript (1 CPU Kern - Die Abschreckung)...\n")
t_start_r  <- Sys.time()
res_r      <- run_mh_pure_r(samples_per_chain, nchains, data, mu_obs, sigma_obs, base_seed)
t_end_r    <- Sys.time()
time_r     <- as.numeric(difftime(t_end_r, t_start_r, units = "secs"))
cat("   ⏱️ Zeit: ", round(time_r, 4), " Sekunden.\n")

# 2. R-Subprozess-Parallelisierung (mclapply)
cat("⏳ 2. Berechne R-Parallel-Subprozesse (parallel::mclapply)......\n")
t_start_mcl <- Sys.time()
res_mcl     <- run_mh_r_subprocesses(samples_per_chain, nchains, data, mu_obs, sigma_obs, base_seed)
t_end_mcl   <- Sys.time()
time_mcl    <- as.numeric(difftime(t_end_mcl, t_start_mcl, units = "secs"))
cat("   ⏱️ Zeit: ", round(time_mcl, 4), " Sekunden.\n")

# 3. Serieller Rcpp-Lauf (1 CPU Kern)
cat("⏳ 3. Berechne serielles Rcpp (1 CPU Kern)...\n")
t_start_serial <- Sys.time()
res_serial     <- run_mh_rcpp_serial(samples, nchains, data, mu_obs, sigma_obs, base_seed)
t_end_serial   <- Sys.time()
time_serial    <- as.numeric(difftime(t_end_serial, t_start_serial, units = "secs"))
cat("   ⏱️ Zeit: ", round(time_serial, 4), " Sekunden.\n")

# 4. Paralleler RcppParallel-Lauf (Intel TBB)
cat("⏳ 4. Berechne RcppParallel TBB (Alle CPU Threads)...\n")
t_start_tbb  <- Sys.time()
res_tbb      <- run_mh_rcpp_parallel(samples, nchains, data, mu_obs, sigma_obs, base_seed)
t_end_tbb    <- Sys.time()
time_tbb     <- as.numeric(difftime(t_end_tbb, t_start_tbb, units = "secs"))
cat("   ⏱️ Zeit: ", round(time_tbb, 4), " Sekunden.\n")

# 5. GPGPU OpenCLeaR Laufzeit (Aus deiner Hauptdatei)
cat("⏳ 5. Berechne OpenCLeaR GPGPU (iGPU)...\n")
t_start_gpu  <- Sys.time()
res_gpu      <- parallel_MH_sampler(as.integer(samples), as.integer(nchains), data, mu_obs, sigma_obs)
t_end_gpu    <- Sys.time()
time_gpu     <- as.numeric(difftime(t_end_gpu, t_start_gpu, units = "secs"))
cat("   ⏱️ Zeit: ", round(time_gpu, 4), " Sekunden.\n")

# ==============================================================================
# 📊 --- ENTSCHEIDENDER END-BERICHT --- 📊
# ==============================================================================
cat("\n📊 ================== FINALER CORES VS. GPGPU VERGLEICH ==================\n")
cat(" 🔴 Reines R-Skript (1 Core)       : ", round(time_r, 4), " Sek.\n")
cat(" 🟤 R-Subprozesse (mclapply Multi) : ", round(time_mcl, 4), " Sek.   | Beschleunigung: ", round(time_r / time_mcl, 2), "x\n")
cat(" 🟠 Nativer C++ Kern (1 Thread)    : ", round(time_serial, 4), " Sek.   | Beschleunigung: ", round(time_r / time_serial, 2), "x\n")
cat(" 🟡 RcppParallel TBB (CPU Threads) : ", round(time_tbb, 4), " Sek.   | Beschleunigung: ", round(time_r / time_tbb, 2), "x\n")
cat(" 🟢 OpenCLeaR GPGPU (iGPU)         : ", round(time_gpu, 4), " Sek.   | Beschleunigung: ", round(time_r / time_gpu, 2), "x\n")
cat("==========================================================================\n")
