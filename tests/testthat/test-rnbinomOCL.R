test_that("OpenCL version of rnbinom works", {
  # Überspringen, falls kein OpenCL-Gerät aktiviert werden kann
  if (!isTRUE(getOption("OpenCLeaR.initialized"))) skip("Kein OpenCL-Gerät verfügbar")
  set.seed(42)
  expect_gt(ks.test(rnbinom(100,2,0.5),rnbinomOCL(100,2,0.5))$p.value, 0.01)
  rlang::inform("rnbinomOCL ... passed")
})
