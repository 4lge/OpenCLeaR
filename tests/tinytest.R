if (requireNamespace("tinytest", quietly = TRUE)) {
  is_pocl <- FALSE
  if (OpenCLeaR::EnsureOpenclInitialized()) {
    devs <- tryCatch(OpenCLeaR::GetDeviceList(), error = function(e) NULL)
    if (!is.null(devs) && nrow(devs) > 0L) {
      is_pocl <- any(grepl("pocl|portable", tolower(paste(devs$Platform, devs$Name))))
    }
  }

  if (is_pocl) {
    ## PoCL LLVM-18 has an upstream heap double-free when compiling many kernels in one process.
    ## Isolate each test file in a fresh Rscript subprocess so PoCL's LLVM state resets cleanly.
    test_dir <- system.file("tinytest", package = "OpenCLeaR")
    test_files <- sort(list.files(test_dir, pattern = "\\.[Rr]$", full.names = TRUE))
    rscript_bin <- file.path(R.home("bin"), "Rscript")

    for (tf in test_files) {
      expr <- sprintf(
        "res <- tinytest::run_test_file(%s); if (any(!as.logical(res))) quit(status = 1L)",
        deparse(tf)
      )
      status <- system2(rscript_bin, args = c("-e", shQuote(expr)))
      if (!identical(status, 0L)) {
        stop("Test file failed under PoCL subprocess isolation: ", basename(tf))
      }
    }
  } else {
    tinytest::test_package("OpenCLeaR")
  }
}

