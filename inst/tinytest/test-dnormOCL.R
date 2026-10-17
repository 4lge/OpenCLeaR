source("setup.R", local = TRUE)
exit_file("test not ready")
# Überspringen, falls kein OpenCL-Gerät aktiviert werden kann
  if (!isTRUE(getOption("OpenCLeaR.initialized"))) exit_file("Kein OpenCL-Gerät verfügbar")

  set.seed(42)
  ## TODO
  ##expect_equal(dnorm(seq(-3,3,by=0.1),0,1),dnormCL(seq(-3,3,by=0.1),0,1))
  rlang::inform("dnormCL ... passed")
