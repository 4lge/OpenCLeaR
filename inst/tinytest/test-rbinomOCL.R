source("setup.R", local = TRUE)

  # Überspringen, falls kein OpenCL-Gerät aktiviert werden kann
  if (!isTRUE(getOption("OpenCLeaR.initialized"))) exit_file("Kein OpenCL-Gerät verfügbar")
  set.seed(42)
  expect_true(ks.test(rbinom(100,20,0.3),rbinomOCL(100,20,0.3))$p.value > 0.01)
  rlang::inform("rbinomOCL ... passed")

