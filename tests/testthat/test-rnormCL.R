test_that("OpenCL version of rnorm works", {
  # Überspringen, falls kein OpenCL-Gerät aktiviert werden kann
  if (!isTRUE(getOption("OpenCLeaR.initialized"))) skip("Kein OpenCL-Gerät verfügbar")

  
  expect_gt(ks.test(rnorm(100,0,1),rnormCL(100,0,1))$p.value, 0.01)
  rlang::inform("rnormCL ... passed")
})
