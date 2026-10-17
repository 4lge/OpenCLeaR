test_that("OpenCL version of rchisq works", {
  # Überspringen, falls kein OpenCL-Gerät aktiviert werden kann
  if (!isTRUE(getOption("OpenCLeaR.initialized"))) skip("Kein OpenCL-Gerät verfügbar")
  set.seed(42)
  expect_gt(ks.test(rchisq(100,10),rchisqOCL(100,10))$p.value, 0.01)
  rlang::inform("rchisqOCL ... passed")
})
