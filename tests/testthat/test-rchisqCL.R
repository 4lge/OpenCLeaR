test_that("OpenCL version of rchisq works", {
  # Überspringen, falls kein OpenCL-Gerät aktiviert werden kann
  if (!isTRUE(getOption("OpenCLeaR.initialized"))) skip("Kein OpenCL-Gerät verfügbar")

  expect_gt(ks.test(rchisq(100,10),rchisqCL(100,10))$p.value, 0.01)
  rlang::inform("rchisqCL ... passed")
})
