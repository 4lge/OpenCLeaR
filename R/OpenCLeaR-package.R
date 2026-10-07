##' @import Rcpp
##' @importFrom inline cxxfunction
##' @importFrom Rcpp evalCpp sourceCpp
##' @useDynLib OpenCLeaR, .registration = TRUE
"_PACKAGE"

.OpenCLeaR_Env <- new.env(parent = emptyenv())

## onLoad function:
.onLoad <- function(libname, pkgname) {
    if (.Platform$OS.type == "windows") {
        Sys.setenv(CUDA_CACHE_DISABLE = "1")
        Sys.setenv(OMP_NUM_THREADS = "1") 
    }   
    
    .OpenCLeaR_Env$active_device_ptr <- NULL
    .OpenCLeaR_Env$active_platform_id <- 0
    .OpenCLeaR_Env$active_device_id   <- 0    

    ## 🚀 Den echten, absoluten Installationspfad der Kernel im Paket ermitteln!
    kernels_dir <- system.file("kernels", package = pkgname, lib.loc = libname)
    if (kernels_dir == "") {
        ## Fallback für die lokale Entwicklungsumgebung
        kernels_dir <- normalizePath("./kernels", mustWork = FALSE)
    }
    .OpenCLeaR_Env$kernels_path <- kernels_dir
    
    inline::registerPlugin("OpenCLeaR", inlineCxxPlugin)
    inline::registerPlugin("OpenCLeaRFloat", inlineCxxPluginFloat)
    inline::registerPlugin("OpenCLeaRDouble", inlineCxxPluginDouble)
    
    options(OpenCLeaR.initialized = FALSE)
    
    ## 2. 🚀 DIE PERFEKTE STARTUP-MELDUNG: Erscheint sofort beim Laden der Library!
    packageStartupMessage(
        "\n==========================================================================\n",
        "  (Kernels path: ", kernels_dir, ").\n",
        "⚠️  [OpenCLeaR] OpenCL environment loaded but NOT yet bound to hardware!\n",
        "👉 PLEASE RUN: ActivateDeviceWithIndex(0) to select and initialize your GPU/CPU.\n",
        "=========================================================================="
    )
}

##' Initialzes OpenCL driver.
##'
##' It tries also to silently fail on installations without any OpenCL available.
##' This is needed to be built e.g. on CRANs win-builder platform or other CRAN
##' package checkers.
##' @export
ensure_opencl_initialized <- function() {
  # Wenn schon erfolgreich initialisiert, direkt zurückkehren
  if (isTRUE(getOption("OpenCLeaR.initialized"))) return(TRUE)
  # 🪟 WINDOWS-DOCKER-SCHUTZWALL: Registry prüfen, bevor C++ die DLL lädt!
  if (.Platform$OS.type == "windows") {
    has_vendors <- tryCatch({
      # Scannt den offiziellen Khronos-Registry-Pfad nach installierten Treibern
      vendors <- utils::readRegistry("SOFTWARE\\Khronos\\OpenCL\\Vendors", "HLM")
      if(GetKernelsPath() == "" || nchar(GetKernelsPath()) == 0){
        kernelsPath <- system.file("kernels", package = "OpenCLeaR") # no pkgname here!
        SetKernelsPath(kernelsPath) # Der von Rcpp generierte saubere Aufruf
      }
      length(vendors) > 0
    }, error = function(e) FALSE)
    
    if (!has_vendors) {
      # Keine Treiber installiert! Sofortiger Abbruch ohne DLL-Aufruf
      options(OpenCLeaR.initialized = FALSE)
      return(FALSE)
    }
  } else {
      if(GetKernelsPath() == "" || nchar(GetKernelsPath()) == 0){
        kernelsPath <- system.file("kernels", package = "OpenCLeaR")
        SetKernelsPath(kernelsPath) # Der von Rcpp generierte saubere Aufruf
      }
  }

  # Versuche die Hardware zu aktivieren
  status <- tryCatch({
    # 🚀 SCHRITT 1: Die Hardware absolut sicher und blockfrei scannen (setupDevices)
    InitCL()

    # 🚀 SCHRITT 2: Erst jetzt das beste Gerät aus der geladenen Liste aktivieren!

    # done in initCl with Index(0) ActivateDeviceWithMostFlops()
    
    # JETZT PRÜFEN: Ist es ein echtes Gerät oder nur das Dummy-Objekt?
    if (IsOpenCLReady()) {
      options(OpenCLeaR.initialized = TRUE)
      TRUE
    } else {
      options(OpenCLeaR.initialized = FALSE)
      FALSE
    }
  }, error = function(e) {
    options(OpenCLeaR.initialized = FALSE)
    FALSE
  })
  
  return(status)
}

#' Holt den aktuell im C++-Backend gesetzten Kernel-Pfad
#' @return Ein String mit dem Pfad
#' @export
GetKernelsPath <- function() {
  # Nutzt den sicheren Tunnel zur neuen internen C++-Funktion
  return(OpenCLeaR:::.GetKernelsPath_cpp())
}


#' Activate OpenCL Device via Index
#' @return logical, indicating success
#' @export
ActivateDeviceWithIndex <- function(idx) {
    idx_int <- as.integer(idx)
    env <- OpenCLeaR:::.OpenCLeaR_Env

    # 1. Hardware-Tabelle einlesen
    devs <- tryCatch({ GetDeviceList() }, error = function(e) NULL)
    if (is.null(devs) || !is.data.frame(devs)) {
        stop("💥 [OpenCLeaR] Hardware-Tabelle konnte nicht gelesen werden!")
    }

    if (idx_int < 0 || idx_int >= nrow(devs)) {
        warning("💥 [OpenCLeaR] Ungültiger Index: ", idx_int)
        return(invisible(FALSE))
    }

    # Treiber-Koordinaten für das Zielgerät auslesen
    ziel_platform <- as.integer(devs[devs$Index == idx_int, "Platform_ID"])
    ziel_device   <- as.integer(devs[devs$Index == idx_int, "Device_ID"])

    # 2. 🎯 UNZERSTÖRBARER COCKPIT-VERGLEICH REIN AUF HARDWARE-EBENE:
    if (OpenCLeaR:::.is_device_bound_cpp()) {
        active_info <- GetActiveDeviceInfo()

        # Wir holen uns die echten, vom aktuellen Gerät getragenen Treiber-IDs
        aktuelle_platform <- as.integer(active_info$Platform_ID)
        aktuelles_device   <- as.integer(active_info$Device_ID)

        # Nur wenn exakt diese Hardware-Kombination schon läuft, blockieren wir!
        if (!is.null(aktuelle_platform) && aktuelle_platform == ziel_platform &&
            !is.null(aktuelles_device)   && aktuelles_device == ziel_device) {
            message("  ⏱️ [OpenCLeaR] Gerät ist bereits aktiv. Aufruf blockiert.")
            return(invisible(TRUE))
        }
    }

    # 3. ZÜNDUNG:
    if (.Platform$OS.type == "windows") {
        ActivateDeviceWithIndex_Async(idx_int)
    } else {
        ActivateDeviceWithIndex_Native(idx_int)
    }

    # 4. TRANSIENTEN POINTER BITSCHARF INITIALISIEREN:
    #cat("🔄 [OpenCLeaR] Erzeuge transienten C++ Pointer (Platform:", ziel_platform, ", Device:", ziel_device, ")\n")
    #env$active_device_ptr <- OpenCLeaR:::.create_transient_device_cpp(ziel_platform, ziel_device, env$kernels_path)

    return(invisible(TRUE))
}
