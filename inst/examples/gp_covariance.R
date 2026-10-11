library(OpenCLeaR)

cat("⏳ Kompiliere GPGPU-Laufzeit-Objekt für GP-Kovarianz via oclFunction...\n")

# Die Argument-Namen in signature MÜSSEN exakt mit den Variablen im C++-Interface übereinstimmen!
parallel_GP_covariance <- oclFunction(
    signature = signature(
        X            = "numeric",
        N            = "integer",
        length_scale = "numeric",
        sigma_f_sq   = "numeric",
        sigma_n_sq   = "numeric"
    ),
    kernel_file     = "gp_kernel.cl",
    interface_file  = "gp_covariance.cpp",
    force_float     = FALSE # TRUE für FP32-Turbo, FALSE für FP64-Präzisionstest
)

# Test-Infrastruktur zum Ausführen:
run_gp_test <- function(N_dim = 2000L) {
  ActivateDeviceWithIndex(0) # NVIDIA GPU aktivieren
  
  X_inputs  <- sort(runif(N_dim, min = 0, max = 10))
  l_param   <- 1.5
  sf2_param <- 2.0
  sn2_param <- 1e-5
  
  cat("⏱️ Starte Berechnung der Kernel-Matrix auf der GPU...\n")
  t_start <- Sys.time()
  
  # Aufruf des kompilierten Objekts
  flat_result <- parallel_GP_covariance(X_inputs, N_dim, l_param, sf2_param, sn2_param)
  
  time_total <- as.numeric(difftime(Sys.time(), t_start, units = "secs"))
  cat(sprintf("🎉 Fertig! Zeit: %.4f Sekunden.\n", time_total))
  
  # Rekonstruktion in eine echte R N x N Matrix
  return(matrix(flat_result, nrow = N_dim, ncol = N_dim))
}
