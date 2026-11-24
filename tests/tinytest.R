if (requireNamespace("tinytest", quietly = TRUE)) {
  library(OpenCLeaR)

  devs <- tryCatch(GetDeviceList(), error = function(e) NULL)
  has_device <- !is.null(devs) && is.data.frame(devs) && nrow(devs) > 0

  if (!has_device) {
    message("No OpenCL devices available; skipping OpenCLeaR test suite.")
  } else {
    dev_idx <- suppressWarnings(as.integer(Sys.getenv("OPENCLEAR_TEST_DEVICE", "0")))
    if (is.na(dev_idx) || dev_idx < 0 || dev_idx >= nrow(devs)) {
      dev_idx <- 0L
    }

    match_pos <- which(devs$Index == dev_idx)
    dev_name <- if (length(match_pos) > 0) devs$Name[match_pos] else devs$Name

    # PoCL exposes CPU devices as "cpu-..." or "pthread-..." rather than "PoCL" in CL_DEVICE_NAME
    is_pocl <- isTRUE(grepl("^(cpu|pthread)-|pocl|portable computing", dev_name, ignore.case = TRUE))

    # Fallback check via clinfo on Linux if only 1 device/platform is present and name didn't match
    if (!is_pocl && nrow(devs) == 1 && identical(Sys.info()[["sysname"]], "Linux") && nzchar(Sys.which("clinfo"))) {
      cl_out <- tryCatch(system("clinfo", intern = TRUE, ignore.stderr = TRUE), error = function(e) character(0))
      is_pocl <- any(grepl("pocl", cl_out, ignore.case = TRUE))
    }

    if (isTRUE(is_pocl)) {
      message(sprintf("PoCL device detected (%s); running lightweight regression suite only.", dev_name))
      tinytest::run_test_file(
        system.file("tinytest", "test_math_lib_and_rng.R", package = "OpenCLeaR")
      )
    } else {
      tinytest::test_package("OpenCLeaR")
    }
  }
}

