source("setup.R", local = TRUE)
# Überspringen, falls kein OpenCL-Gerät aktiviert werden kann
  if (!isTRUE(getOption("OpenCLeaR.initialized"))) exit_file("Kein OpenCL-Gerät verfügbar")
  set.seed(42)
  expect_true(ks.test(rgamma(100,1,1),rgammaOCL(100,1,1))$p.value > 0.01)
  rlang::inform("rgammaOCL ... passed")
