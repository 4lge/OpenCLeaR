test_that("OpenCL version of rnorm works", {
  # Überspringen, falls kein OpenCL-Gerät aktiviert werden kann
  if (!isTRUE(getOption("OpenCLeaR.initialized"))) skip("Kein OpenCL-Gerät verfügbar")

  set.seed(42)
  expect_gt(ks.test(rnorm(100,0,1),rnormOCL(100,0,1))$p.value, 0.01)
  rlang::inform("rnormOCL ... passed")
})
