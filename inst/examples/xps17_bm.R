# Bereinige alte temporäre Dateien
unlink("stage_*.res")

# Rufe jede Stage in einem eigenen, isolierten R-Prozess auf!
# Das verhindert das "double free" im Intel-Treiber komplett.
for (stage_id in 0:4) {
  cmd <- sprintf("Rscript OpenCLeaR/inst/examples/xps17_single_run.R %d", stage_id)
  system(cmd)
}

# --- Sammle die Ergebnisse für die finale Tabelle ---
cat("\n📊 ================== FINALER XPS 17 CORES VS. GPGPU VERGLEICH ==================\n")
cat(sprintf(" %-40s | %-10s\n", "Architektur / Triebwerk", "Laufzeit"))
cat(paste0(rep("-", 55), collapse = ""), "\n")

for (stage_id in 0:4) {
  file_name <- sprintf("stage_%d.res", stage_id)
  if (file.exists(file_name)) {
    line <- readLines(file_name, n = 1)
    parts <- strsplit(line, ";")[[1]]
    cat(sprintf(" %-40s | %-10s\n", parts[2], paste0(parts[3], "s")))
  } else {
    cat(sprintf(" %-40s | CRASH/NA\n", paste0("Stage ", stage_id)))
  }
}
cat("==================================================================================\n")
