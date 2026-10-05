test_that("OpenCL version of dnorm works", {
  # Überspringen, falls kein OpenCL-Gerät aktiviert werden kann
  if (!isTRUE(getOption("OpenCLeaR.initialized"))) skip("Kein OpenCL-Gerät verfügbar")

  
  expect_equal(dnorm(seq(-3,3,by=0.1),0,1),dnormCL(seq(-3,3,by=0.1),0,1))
  rlang::inform("dnormCL ... passed")
})
