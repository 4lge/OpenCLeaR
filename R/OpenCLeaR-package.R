##' @import Rcpp
##' @importFrom inline cxxfunction
##' @importFrom Rcpp evalCpp sourceCpp
##' @importFrom methods signature
##' @useDynLib OpenCLeaR, .registration = TRUE


"_PACKAGE"

## FIXME: is this really used?? or ueful??
.OpenCLeaR_Env <- new.env(parent = emptyenv())


## onLoad function:
 .onLoad <- function(libname, pkgname) {
     ## 🛡️ NVIDIA-TURBO FÜR WINDOWS:
     ## Wir schalten den fehlerhaften Nvidia-Festplatten-Cache komplett ab!
     if (.Platform$OS.type == "windows") {
         Sys.setenv(CUDA_CACHE_DISABLE = "1")
         Sys.setenv(OMP_NUM_THREADS = "1") # Verhindert, dass OpenMP-Hintergrundthreads im R-Lader blockieren
     }
     ## 🚀 Den echten, absoluten Installationspfad der Kernel im Paket ermitteln!
     kernel_dir <- system.file("kernel", package = pkgname, lib.loc = libname)
     if (kernel_dir == "") {
         ## Fallback für die lokale Entwicklungsumgebung
         kernel_dir <- normalizePath("./kernel", mustWork = FALSE)
     }
     .OpenCLeaR_Env$kernel_path <- kernel_dir

     ## Meldet alle drei Plugins beim Laden des Pakets an
     inline::registerPlugin("OpenCLeaR", inlineCxxPlugin)
     inline::registerPlugin("OpenCLeaRFloat", inlineCxxPluginFloat)
     inline::registerPlugin("OpenCLeaRDouble", inlineCxxPluginDouble)

     ## Wir setzen im R-Zustand standardmäßig ein Flag auf FALSE.
     ## Es wird erst TRUE, wenn die Initialisierung später klappt.
     options(OpenCLeaR.initialized = FALSE)
     options(OpenCLeaR.has_fp64 = FALSE)
 }


## 🏎️ 2. ONATTACH: Der perfekte Ort für den fehlersicheren Hardware-Autostart!
.onAttach <- function(libname, pkgname) {
    ## Zeige den Hinweis NUR, wenn KEIN Gerät automatisch gebunden werden konnte!
    if (!isTRUE(getOption("OpenCLeaR.initialized"))) {
        kernel_dir <- .OpenCLeaR_Env$kernel_path
        packageStartupMessage(
            "\n==========================================================================\n",
            "  (Kernels path: ", kernel_dir, ").\n",
            "⚠️  [OpenCLeaR] OpenCL environment loaded but NOT yet bound to hardware!\n",
            "👉 PLEASE RUN: ActivateDeviceWithIndex(0) to select and initialize your GPU/CPU.\n",
            "=========================================================================="
        )
    }
}


##' Aktiviert ein OpenCL-Gerät absolut fehlersicher und blockfrei
##' 
##' @param idx Optionaler Integer-Index des Geräts (Standard: 0)
##' @export
ActivateDevice <- function(idx = 0) {
    idx_int <- as.integer(idx)
    env <- OpenCLeaR:::.OpenCLeaR_Env

    # =========================================================================
    # 🪟 DER UNZERSTÖRBARE v0.5.10 WINDOWS-PFAD (Direkt-Backport)
    # =========================================================================
    if (.Platform$OS.type == "windows") {
        devs <- tryCatch({ GetDeviceList() }, error = function(e) NULL)
        if (is.null(devs) || !is.data.frame(devs)) {
            stop("💥 [OpenCLeaR] Windows-Hardware-Tabelle konnte nicht gelesen werden!")
        }

        if (idx_int < 0 || idx_int >= nrow(devs)) {
            warning("💥 [OpenCLeaR] Ungültiger Windows-Index: ", idx_int)
            return(invisible(FALSE))
        }

        ziel_platform <- as.integer(devs[devs$Index == idx_int, "Platform_ID"])
        ziel_device   <- as.integer(devs[devs$Index == idx_int, "Device_ID"])

        cat("🔄 [OpenCLeaR Windows] Zünde v0.5.10 Pointer-Brücke (Platform:", ziel_platform, ", Device:", ziel_device, ")\n")
        
        # Erzeugt das transiente Objekt im RAM ohne Singleton-Sperre:
        env$active_device_ptr <- OpenCLeaR:::.create_transient_device_cpp(ziel_platform, ziel_device, env$kernel_path)
        
        options("OpenCLeaR.initialized" = TRUE)
        options("OpenCLeaR.active_device" = idx_int)
        options("OpenCLeaR.has_fp64" = as.logical(devs[devs$Index == idx_int, "FP64_Capable"]))
        
        return(TRUE)
    }

    # =========================================================================
    # 🐧 LINUX / MAC v0.6.5 ORIGINAL-PFAD (Unverändert)
    # =========================================================================
    if (!isTRUE(getOption("OpenCLeaR.initialized"))) {
        initialized_now <- ensure_opencl_initialized()
        if (!initialized_now) {
            stop("💥 [OpenCLeaR] OpenCL-Subsystem konnte nicht initialisiert werden!")
        }
    }

    devs <- tryCatch({ GetDeviceList() }, error = function(e) NULL)
    if (is.null(devs) || !is.data.frame(devs)) {
        stop("💥 [OpenCLeaR] Hardware-Tabelle konnte nicht gelesen werden!")
    }

    if (idx_int < 0 || idx_int >= nrow(devs)) {
        warning("💥 [OpenCLeaR] Ungültiger Index: ", idx_int)
        return(invisible(FALSE))
    }

    ziel_platform <- as.integer(devs[devs$Index == idx_int, "Platform_ID"])
    ziel_device   <- as.integer(devs[devs$Index == idx_int, "Device_ID"])

    if (OpenCLeaR:::.is_device_bound_cpp()) {
        active_info <- tryCatch({ GetActiveDeviceInfo() }, error = function(e) NULL)
        if (!is.null(active_info)) {
            aktuelle_platform <- as.integer(active_info$Platform_ID)
            aktuelles_device   <- as.integer(active_info$Device_ID)
            if (!is.null(aktuelle_platform) && aktuelle_platform == ziel_platform &&
                !is.null(aktuelles_device)   && aktuelles_device == ziel_device) {
                return(invisible(TRUE))
            }
        }
    }
    
    success <- tryCatch({
        ActivateDeviceWithIndex_Native(idx_int)
        TRUE
    }, error = function(e) FALSE)
    
    if (success) {
        options("OpenCLeaR.initialized" = TRUE)
        options("OpenCLeaR.active_device" = idx_int)
        options("OpenCLeaR.has_fp64" = tryCatch({ GetActiveDeviceInfo()$FP64_Capable }, error = function(e) FALSE))
        return(TRUE)
    } else {
        options("OpenCLeaR.initialized" = FALSE)
        options("OpenCLeaR.has_fp64" = FALSE)
        return(FALSE)
    }
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
        kernelPath <- system.file("kernel", package = "OpenCLeaR") # no pkgname here!
        SetKernelsPath(kernelPath) # Der von Rcpp generierte saubere Aufruf
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
        kernelPath <- system.file("kernel", package = "OpenCLeaR")
        SetKernelsPath(kernelPath) # Der von Rcpp generierte saubere Aufruf
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

##' Holt den aktuell im C++-Backend gesetzten Kernel-Pfad
##' @return Ein String mit dem Pfad
##' @export
GetKernelsPath <- function() {
                                        # Nutzt den sicheren Tunnel zur neuen internen C++-Funktion
    return(OpenCLeaR:::.GetKernelsPath_cpp())
}

##' Aktiviert ein OpenCL-Gerät absolut fehlersicher
##' @param idx Der Index des zu aktivierenden Geräts (Standard: 0)
##' @export
ActivateDeviceWithIndex <- function(idx) {
   ActivateDevice(idx)
}
