.onLoad <- function(libname, pkgname) {
  kernelsPath <- system.file("kernels", package = pkgname)
  print(kernelsPath)
  SetKernelsPath(kernelsPath)
}
