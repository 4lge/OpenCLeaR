source("setup.R", local = TRUE)

  # Überspringen, falls kein OpenCL-Gerät aktiviert werden kann
  if (!isTRUE(getOption("OpenCLeaR.initialized"))) exit_file("Kein OpenCL-Gerät verfügbar")
  set.seed(42)
  expect_true(ks.test(rt(100,1),rtOCL(100,1))$p.value > 0.01)
  expect_true(ks.test(rt(100,10),rtOCL(100,10))$p.value > 0.01)
  expect_true(ks.test(rt(100,42),rtOCL(100,42))$p.value > 0.01)
  rlang::inform("rtOCL ... passed")
