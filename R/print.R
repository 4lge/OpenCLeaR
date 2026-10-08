#' S3 Print-Methode für OpenCL-Geräteinformationen
#' @param x Ein Objekt der Klasse OpenCLDeviceInfo
#' @param ... Weitere Argumente (ignoriert)
#' @method print OpenCLDeviceInfo
#' @export
print.OpenCLDeviceInfo <- function(x, ...) {
  # 🚀 SCHUTZGÜRTEL: Hilfsfunktion fängt leere oder korrupte Felder unzerstörbar ab!
  align_l <- function(text, width = 58) {
    if (is.null(text) || length(text) == 0 || is.na(text)) {
      txt <- "NA"
    } else {
    txt <- as.character(text)
    }
    if (nchar(txt) >= width) return(substring(txt, 1, width))
    paste0(txt, paste(rep(" ", width - nchar(txt)), collapse = ""))
  }
  
  # Speicher lesbar formatieren (RAM vs VRAM)
  mem_type <- if (isTRUE(x$Uses_RAM)) "RAM" else "VRAM"
  
  # 🚀 DER REINE, NATIVE R-DRUCK (Komplett bereinigt und tippfehlerfrei):
  cat("|----------------.------------------------------------------------------------|\n")
  cat(paste0("| Device Index   | ", align_l(x$Index), " |\n"))
  cat(paste0("| Platform ID    | ", align_l(x$Platform_ID), " |\n")) # 🎯 Buchstabendreher BITGENAU korrigiert!
  cat(paste0("| Device ID      | ", align_l(x$Device_ID), " |\n"))
  cat(paste0("| Device Name    | ", align_l(x$Name), " |\n"))
  cat(paste0("| Device Vendor  | ", align_l(x$Vendor), " |\n"))
  cat(paste0("| Device Driver  | ", align_l(paste0(x$Driver_Version, " (", x$OS, ")")), " |\n"))
  cat(paste0("| OpenCL Version | ", align_l(x$OpenCL_Version), " |\n"))
  
  # Berechnete Kerne und TFLOPs formatiert ausgeben
  compute_str <- paste0(x$Compute_Units, " at ", x$Clock_MHz, " MHz (", x$Cores, " cores, ", round(x$TFLOPs, 3), " TFLOPs/s)")
  cat(paste0("| Compute Units  | ", align_l(compute_str), " |\n"))
  
  # Cache und Speicherlimits
  mem_str <- paste0(x$Memory_MB, " MB ", mem_type, ", ", x$Global_Cache_KB, " KB global / ", x$Local_Cache_KB, " KB local")
  cat(paste0("| Memory, Cache  | ", align_l(mem_str), " |\n"))
  
  buf_str <- paste0(x$Max_Buffer_MB, " MB global, ", x$Max_Constant_KB, " KB constant")
  cat(paste0("| Buffer Limits  | ", align_l(buf_str), " |\n"))
  
  # FP64 Fähigkeit
  cat(paste0("| FP64 capable   | ", align_l(if (isTRUE(x$FP64_Capable)) "TRUE" else "FALSE"), " |\n"))
  cat("|----------------'------------------------------------------------------------|\n")
  
  invisible(x) 
}
