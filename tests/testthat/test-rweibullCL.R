test_that("OpenCL version of rweibull works", {
  # Überspringen, falls kein OpenCL-Gerät aktiviert werden kann
  if (!isTRUE(getOption("OpenCLeaR.initialized"))) skip("Kein OpenCL-Gerät verfügbar")

  expect_gt(ks.test(rweibull(100,1,pi),rweibullCL(100,1,pi))$p.value, 0.01)
  rlang::inform("rweibullCL ... passed")
})
