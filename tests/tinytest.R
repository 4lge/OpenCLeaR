
if (requireNamespace("tinytest", quietly = TRUE)) {
  is_pocl <- FALSE
  if (OpenCLeaR::EnsureOpenclInitialized()) {
    devs <- tryCatch(OpenCLeaR::GetDeviceList(), error = function(e) NULL)
    if (!is.null(devs) && nrow(devs) > 0L) {
      is_pocl <- any(grepl("pocl|portable", tolower(paste(devs$Platform, devs$Name))))
    }
  }
  if (is_pocl) {
    ## PoCL LLVM-18 triggers an upstream double-free when compiling >40 kernels in one R process;
    ## run the core multi-lib, RNGkind, and a small selection of distribution smoke tests on PoCL.
    tinytest::run_test_file(system.file("tinytest", "test_math_lib_and_rng.R", package = "OpenCLeaR"))
    tinytest::run_test_file(system.file("tinytest", "test-dnormOCL.R", package = "OpenCLeaR"))
    tinytest::run_test_file(system.file("tinytest", "test-pnormOCL.R", package = "OpenCLeaR"))
    tinytest::run_test_file(system.file("tinytest", "test-qnormOCL.R", package = "OpenCLeaR"))
    tinytest::run_test_file(system.file("tinytest", "test-rnormOCL.R", package = "OpenCLeaR"))
    tinytest::run_test_file(system.file("tinytest", "test-dmvnormOCL.R", package = "OpenCLeaR"))
    tinytest::run_test_file(system.file("tinytest", "test-pmvnormOCL.R", package = "OpenCLeaR"))
    tinytest::run_test_file(system.file("tinytest", "test-qmvnormOCL.R", package = "OpenCLeaR"))
    tinytest::run_test_file(system.file("tinytest", "test-rmvnormOCL.R", package = "OpenCLeaR"))
    tinytest::run_test_file(system.file("tinytest", "test-dbetaOCL.R", package = "OpenCLeaR"))
    tinytest::run_test_file(system.file("tinytest", "test-pbetaOCL.R", package = "OpenCLeaR"))
    tinytest::run_test_file(system.file("tinytest", "test-qbetaOCL.R", package = "OpenCLeaR"))
    tinytest::run_test_file(system.file("tinytest", "test-rbetaOCL.R", package = "OpenCLeaR"))
  } else {
    tinytest::test_package("OpenCLeaR")
  }
}

