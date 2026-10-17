test_that("OpenCL version of rexp works", {
  # Überspringen, falls kein OpenCL-Gerät aktiviert werden kann
  if (!isTRUE(getOption("OpenCLeaR.initialized"))) skip("Kein OpenCL-Gerät verfügbar")
  set.seed(42)
  expect_gt(ks.test(rexp(100,10),rexpOCL(100,10))$p.value, 0.01)
  rlang::inform("rexpOCL ... passed")
})
