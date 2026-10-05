test_that("OpenCL version of rbeta works", {
  # Überspringen, falls kein OpenCL-Gerät aktiviert werden kann
  if (!isTRUE(getOption("OpenCLeaR.initialized"))) skip("Kein OpenCL-Gerät verfügbar")

  expect_gt(ks.test(rbeta(100,1,1),rbetaCL(100,1,1))$p.value, 0.01)
  rlang::inform("rbetaCL ... passed")
})
