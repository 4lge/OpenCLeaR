#' nmath-Verteilungen fr OpenCL-CL nachladen
#' @param target_dir target path, if NULL (default) 
#'    file.path(system.file(package = "OpenCLeaR"), "kernel") is used.
#' @export
ImportNmathKernels <- function(target_dir = NULL) {
  if (!requireNamespace("opencltools", quietly = TRUE)) {
    stop(paste0(
      " OpenCLeaR Hinweis:\n",
      "Das Paket 'opencltools' ist auf diesem System nicht installiert.\n",
      "Der nmath-Kernel-Import ist nicht verfgbar.\n",
      "Bitte installiere zuerst 'opencltools', falls deine Hardware dies untersttzt."
    ), call. = FALSE)
  }
  
  cat(" Rufe nmath-Bibliothek ab und rekalibriere Typen fr die GPU...\n")
  
  # Code fliegend ber die installierte Bibliothek laden
  c_code <- opencltools::load_kernel_library("nmath")
  
  # Dein unfehlbarer, Base-R-gereinigter Regex-Tunnel
  clean_code <- gsub("/\\*.*?\\*/|//.*?(?=\\n|\\r|$)", "", c_code, perl = TRUE)
  
  c_code_inline <- gsub(
    "(?m)^(\\s*)(?!inline|static|return|if|while|for\\b)([a-zA-Z0-9_]+[\\s\\*]+[a-zA-Z0-9_]+\\s*\\([^\\)]*\\)\\s*(?=\\{))",
    "\\1static inline \\2",
    clean_code,
    perl = TRUE
  )
  
  c_code_inline <- gsub("\\bdouble(\\s*\\*+)?\\b", "real\\1", c_code_inline, perl = TRUE)
  c_code_inline <- gsub("\\bfloat(\\s*\\*+)?\\b", "real\\1", c_code_inline, perl = TRUE)
  c_code_inline <- gsub("\r", "", c_code_inline)
  
  if(is.null(target_dir)){
  #  DER ENTSCHEIDENDE PFAD-GRIFF:
  # Wir schreiben direkt in den AKTUELL INSTALLIERTEN Paket-Ordner im R-System!
  installed_kernel_dir <- system.file("kernel", package = "OpenCLeaR")
  
  # Falls das Verzeichnis im installierten Zustand noch fehlt, fliegend anlegen
  if (installed_kernel_dir == "") {
    # Fallback-Ermittlung des installierten Bibliothekspfads
    installed_kernel_dir <- file.path(system.file(package = "OpenCLeaR"), "kernel")
    dir.create(installed_kernel_dir, recursive = TRUE, showWarnings = FALSE)
  }
  
  target_file <- file.path(installed_kernel_dir, "nmath.cl")
} else {
  target_file <- file.path(target_dir, "nmath.cl")
}
  writeLines(c_code_inline, target_file)
  
  cat(" [OpenCLeaR Runtime] nmath.cl erfolgreich im System-Pfad verankert:\n", target_file, "\n")
  return(TRUE)
}
