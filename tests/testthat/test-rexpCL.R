test_that("OpenCL version of rexp works", {
  # Überspringen, falls kein OpenCL-Gerät aktiviert werden kann
  if (!isTRUE(getOption("OpenCLeaR.initialized"))) skip("Kein OpenCL-Gerät verfügbar")

  expect_gt(ks.test(rexp(100,10),rexpCL(100,10))$p.value, 0.01)
  rlang::inform("rexpCL ... passed")
})
