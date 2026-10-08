#' Holt die detaillierten Hardware-Informationen des aktiven OpenCL-Geräts
#'
#' @return Ein Objekt der Klasse \code{OpenCLDeviceInfo} mitsamt wunderschöner S3-Ausgabe.
#' @export
GetActiveDeviceInfo <- function() {
  # 1. Ruft die interne, versteckte Rcpp-Funktion blockfrei ab
  info <- OpenCLeaR:::.GetActiveDeviceInfo_cpp()
  
  # 2. Die S3-Klasse aufprägen
  class(info) <- "OpenCLDeviceInfo"
  return(info)
}
#' Listet alle im System verfuegbaren OpenCL-Geraete auf
#'
#' @return Ein Objekt der Klasse \code{OpenCLDeviceList} mitsamt kompakter S3-Ausgabe.
#' @export
GetDeviceList <- function() {
  # 1. Ruft die interne, versteckte Rcpp-Funktion blockfrei ab
  df <- OpenCLeaR:::.GetDeviceList_cpp()
  
  # 2. Die S3-Klasse aufprägen (der DataFrame bleibt im Kern erhalten!)
  class(df) <- c("OpenCLDeviceList", "data.frame")
  return(df)
}

#' Holt den aktuell im C++-Backend gesetzten Kernel-Pfad
#' @return Ein String mit dem Pfad
#' @export
GetKernelsPath <- function() {
  # Nutzt den sicheren Tunnel zur neuen internen C++-Funktion
  return(OpenCLeaR:::.GetKernelsPath_cpp())
}

#' S3 Print-Methode für OpenCL-Geräteinformationen
#' @method print OpenCLDeviceInfo
#' @export
print.OpenCLDeviceInfo <- function(x, ...) {
  # 🚀 SCHUTZWALL GEGEN LEERE INITIALISIERUNG (Lazy-Loading-Schutz):
  if (x$Name == "" || x$Compute_Units == 0) {
    cat("|----------------.------------------------------------------------------------|\n")
    cat("| Hinweis        | Es ist aktuell noch kein OpenCL-Geraet im RAM aktiviert.    |\n")
    cat("|                | Bitte rufen Sie zuerst 'ActivateDeviceWithIndex(0)' auf!   |\n")
    cat("|----------------'------------------------------------------------------------|\n")
    return(invisible(x))
  }

  # Hilfsfunktion für linksbündige Ausrichtung (simuliert C++ alignl)
  align_l <- function(text, width = 45) {
    # 🚀 DER REINIGUNGS-FILTER: Entfernt Tabs und unsichtbare Treiber-Geisterzeichen!
    clean_txt <- trimws(as.character(text))
    clean_txt <- gsub("[^[:print:]]", "", clean_txt)
    
    if (nchar(clean_txt) >= width) return(substring(clean_txt, 1, width))
    paste0(clean_txt, paste(rep(" ", width - nchar(clean_txt)), collapse = ""))
  }

  # 🚀 DER REINE, NATIVE R-DRUCK: Genau eine Zeile pro Gerät!
  cat("|----------------.------------------------------------------------------------|\n")
  cat("| Device Index   | Geraete-Name                                  | FP64       |\n")
  cat("|----------------+-----------------------------------------------+------------|\n")
  
  for (i in 1:nrow(x)) {
    idx_str   <- paste0(x$Index[i], " ")
    idx_pad   <- paste0(idx_str, paste(rep(" ", 14 - nchar(idx_str)), collapse = ""))
    name_pad <- align_l(x$Name[i], 45)
    fp64_str <- if (x$FP64_Capable[i]) "JA  " else "NEIN"
    
    cat(paste0("| Idx ", idx_pad, "| ", name_pad, " | ", fp64_str, "       |\n"))
  }
  cat("|----------------'------------------------------------------------------------|\n")
  
  invisible(x) # R-Standard: Gibt das Objekt unsichtbar zurück
}

#' S3 Print-Methode fuer die OpenCL-Geraeteliste
#' @method print OpenCLDeviceList
#' @export
print.OpenCLDeviceList <- function(x, ...) {
  if (nrow(x) == 0) {
    cat("Keine OpenCL-Geraete im System gefunden.\n")
    return(invisible(x))
  }

  # Hilfsfunktion für linksbündige Ausrichtung (simuliert C++ alignl)
  align_l <- function(text, width = 45) {
    txt <- as.character(text)
    if (nchar(txt) >= width) return(substring(txt, 1, width))
    paste0(txt, paste(rep(" ", width - nchar(txt)), collapse = ""))
  }

  cat("|----------------.------------------------------------------------------------|\n")
  cat("| Device Index   | Geraete-Name                                  | FP64       |\n")
  cat("|----------------+-----------------------------------------------+------------|\n")

  for (i in 1:nrow(x)) {
    # 🚀 DIE DYNAMISCHE STRIP-LOGIK:
    # Das ID-Feld hat eine feste Trennwand-Breite von 10 Zeichen ("| ID X    ")
    raw_idx <- as.character(x$Index[i])

    # Wir berechnen das exakte Padding für die Leerzeichen hinter der Ziffer:
    # 10 Zeichen Gesamtbreite - 3 Zeichen für "ID " - Länge der Ziffer
    padding_length <- 10 - 3 - nchar(raw_idx)

    # Sicherheitsnetz, falls die ID wider Erwarten riesig wird
    if (padding_length < 1) padding_length <- 1

    # Perfekt zentrierter ID-String ohne Tabellen-Verschiebung!
    idx_field <- paste0("Idx ", raw_idx, paste(rep(" ", padding_length), collapse = ""))

    name_pad <- align_l(x$Name[i], 45)
    fp64_str <- if (x$FP64_Capable[i]) "JA  " else "NEIN"

    cat(paste0("| ", idx_field, "| ", name_pad, " | ", fp64_str, "       |\n"))
  }
  cat("|----------------'------------------------------------------------------------|\n")

  invisible(x)
}

