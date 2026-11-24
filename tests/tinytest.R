if (requireNamespace("tinytest", quietly = TRUE)) {
  is_pocl <- FALSE
  if (OpenCLeaR::EnsureOpenclInitialized()) {
    devs <- tryCatch(OpenCLeaR::GetDeviceList(), error = function(e) NULL)
    if (!is.null(devs) && nrow(devs) > 0L) {
      is_pocl <- any(grepl("pocl|portable", tolower(paste(devs$Platform, devs$Name))))
    }
  }

  if (is_pocl) {
    ## PoCL 6.0 / LLVM-18 triggers upstream codegen/teardown crashes on certain complex
    ## kernels (e.g., df.cl). Run the core JIT, multi-lib, and RNGkind suite on PoCL;
    ## the full 122-test suite runs on native GPU/OpenCL drivers (macOS Apple Silicon, NVIDIA, AMD, Intel).
    res <- tinytest::run_test_file(system.file("tinytest", "test_math_lib_and_rng.R", package = "OpenCLeaR"))
    if (any(!as.logical(res))) {
      stop("Core PoCL integration test failed.")
    }
  } else {
    tinytest::test_package("OpenCLeaR")
  }
}

