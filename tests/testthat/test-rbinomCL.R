test_that("OpenCL version of rbinom works", {
  # Überspringen, falls kein OpenCL-Gerät aktiviert werden kann
  if (!isTRUE(getOption("OpenCLeaR.initialized"))) skip("Kein OpenCL-Gerät verfügbar")

  expect_gt(ks.test(rbinom(100,20,0.3),rbinomCL(100,20,0.3))$p.value, 0.01)
  rlang::inform("rbinomCL ... passed")
})
