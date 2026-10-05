test_that("OpenCL version of runif works", {
  # Überspringen, falls kein OpenCL-Gerät aktiviert werden kann
  if (!isTRUE(getOption("OpenCLeaR.initialized"))) skip("Kein OpenCL-Gerät verfügbar")

  expect_gt(ks.test(runif(100,-1,1),runifCL(100,-1,1))$p.value, 0.01)
  rlang::inform("runifCL ... passed")
})
