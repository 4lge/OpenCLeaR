test_that("OpenCL version of rt works", {
  # Überspringen, falls kein OpenCL-Gerät aktiviert werden kann
  if (!isTRUE(getOption("OpenCLeaR.initialized"))) skip("Kein OpenCL-Gerät verfügbar")
  set.seed(42)
  if (!ensure_opencl_initialized()) skip("Kein OpenCL-Gerät verfügbar")
  expect_gt(ks.test(rt(100,1),rtOCL(100,1))$p.value, 0.01)
  expect_gt(ks.test(rt(100,10),rtOCL(100,10))$p.value, 0.01)
  expect_gt(ks.test(rt(100,42),rtOCL(100,42))$p.value, 0.01)
  rlang::inform("rtOCL ... passed")
})
