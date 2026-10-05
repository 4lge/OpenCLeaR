test_that("OpenCL version of rgamma works", {
  # Überspringen, falls kein OpenCL-Gerät aktiviert werden kann
  if (!isTRUE(getOption("OpenCLeaR.initialized"))) skip("Kein OpenCL-Gerät verfügbar")

  expect_gt(ks.test(rgamma(100,1,1),rgammaCL(100,1,1))$p.value, 0.01)
  rlang::inform("rgammaCL ... passed")
})
