.onLoad <- function(libname, pkgname) {
  # 1. Deine bestehenden Initialisierungen (z.B. Pfade setzen)
  kernelsPath <- system.file("kernels", package = pkgname)
  packageStartupMessage(paste("kerenl path:",kernelsPath))
  
  # 2. 🚀 DIE DOPPELZÜNDUNG:
  # Wir zwingen R dazu, deine native Zusatz-Registrierung manuell nachzuladen.
  # Das verknüpft dein SEXP-Vehikel blitzschnell im RAM!
  SetKernelsPath(kernelsPath)
}


