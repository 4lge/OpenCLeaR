test_that("OpenCL version of rpois works", {
  # Überspringen, falls kein OpenCL-Gerät aktiviert werden kann
  if (!isTRUE(getOption("OpenCLeaR.initialized"))) skip("Kein OpenCL-Gerät verfügbar")

  expect_gt(ks.test(rpois(100,2),rpoisCL(100,2))$p.value, 0.01)
  rlang::inform("rpoisCL ... passed")
})
