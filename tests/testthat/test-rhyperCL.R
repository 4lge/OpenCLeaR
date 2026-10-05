test_that("OpenCL version of rhyper works", {
  # Überspringen, falls kein OpenCL-Gerät aktiviert werden kann
  if (!isTRUE(getOption("OpenCLeaR.initialized"))) skip("Kein OpenCL-Gerät verfügbar")

  expect_gt(ks.test(rhyper(100,12,8,5),rhyperCL(100,12,8,5))$p.value, 0.01)
  rlang::inform("rhyperCL ... passed")
})
