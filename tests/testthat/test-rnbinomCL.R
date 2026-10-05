test_that("OpenCL version of rnbinom works", {
  # Überspringen, falls kein OpenCL-Gerät aktiviert werden kann
  if (!isTRUE(getOption("OpenCLeaR.initialized"))) skip("Kein OpenCL-Gerät verfügbar")

  expect_gt(ks.test(rnbinom(100,2,0.5),rnbinomCL(100,2,0.5))$p.value, 0.01)
  rlang::inform("rnbinomCL ... passed")
})
