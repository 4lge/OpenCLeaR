test_that("OpenCL version of rbeta works", {
  # Überspringen, falls kein OpenCL-Gerät aktiviert werden kann
  if (!isTRUE(getOption("OpenCLeaR.initialized"))) skip("Kein OpenCL-Gerät verfügbar")
  set.seed(42)
  expect_gt(ks.test(rbeta(100,1,1),rbetaOCL(100,1,1))$p.value, 0.01)
  rlang::inform("rbetaOCL ... passed")
})
