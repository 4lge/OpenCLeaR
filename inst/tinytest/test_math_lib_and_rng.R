library(tinytest)
library(OpenCLeaR)

## 1. Pfadauflösung & Validierung von .resolve_math_lib_files() (läuft auch ohne GPU)
res_helper <- OpenCLeaR:::.resolve_math_lib_files

expect_identical(res_helper(FALSE), character(0))
expect_identical(res_helper(NULL), character(0))
expect_identical(res_helper(character(0)), character(0))

default_lib <- res_helper(TRUE)
expect_equal(length(default_lib), 1L)
expect_true(file.exists(default_lib))
expect_identical(basename(default_lib), "libkernel.cl")

## Fehler bei fehlender lokaler Datei oder nicht vorhandenem Paket
expect_error(res_helper("./does_not_exist_12345.cl"))
expect_error(res_helper("nonexistentpkg12345::foo.cl"))
expect_error(res_helper("invalid::spec::bar.cl"))
expect_error(res_helper(123))

## 2. Echte OpenCL-Integration: geordnete math_lib + mtime-Invalidierung + RNGkind
if (EnsureOpenclInitialized()) {
  ActivateDevice(0)

  old_wd <- getwd()
  tmp_dir <- tempfile("openclear_test_")
  dir.create(tmp_dir)
  on.exit({
    setwd(old_wd)
    CleanCLCache()
    unlink(tmp_dir, recursive = TRUE)
  }, add = TRUE)
  setwd(tmp_dir)

  writeLines(c(
    "inline real custom_shift_normal(real x, real scale, RNG_PROTOTYPE) {",
    "    return x + scale * rnorm_internal((real)0.0f, (real)1.0f, RNG_01_ARGS);",
    "}"
  ), "./custom_helper.cl")

  writeLines(c(
    "__kernel void test_multilib_rng(__global const real* x, __global real* out,",
    "                                const int n, const real scale, const int seed) {",
    "    int i = get_global_id(0);",
    "    if (i >= n) return;",
    "    INIT_RNG(seed + i);",
    "    out[i] = custom_shift_normal(x[i], scale, RNG_ARGS);",
    "}"
  ), "./test_multilib_rng.cl")

  writeLines(c(
    "NumericVector rx(x);",
    "int n = rx.size();",
    "Memory<real> gx(*device, n), gout(*device, n);",
    "for (int i = 0; i < n; ++i) gx[i] = rx[i];",
    "gx.write_to_device();",
    "Kernel k(*device, n, \"test_multilib_rng\", gx, gout, n, as<real>(scale), as<int>(seed));",
    "k.run();",
    "gout.read_from_device();",
    "NumericVector res(n);",
    "for (int i = 0; i < n; ++i) res[i] = gout[i];",
    "return res;"
  ), "./test_multilib_rng.cpp")

  ## A) Xorshift128 + geordnetes math_lib = c("libkernel.cl", "./custom_helper.cl")
  fn_xor <- oclFunction(
    signature      = methods::signature(x = "numeric", scale = "numeric", seed = "integer"),
    kernel_file    = "./test_multilib_rng.cl",
    interface_file = "./test_multilib_rng.cpp",
    math_lib       = c("libkernel.cl", "./custom_helper.cl"),
    RNGkind        = "Xorshift128"
  )
  out_xor <- fn_xor(1:5, scale = 0.05, seed = 42L)
  expect_equal(length(out_xor), 5L)
  expect_true(all(is.finite(out_xor)))
  expect_true(max(abs(out_xor - (1:5))) < 0.5)

  ## B) Mersenne-Twister mit identischem Kernel & Multi-Lib
  fn_mt <- oclFunction(
    signature      = methods::signature(x = "numeric", scale = "numeric", seed = "integer"),
    kernel_file    = "./test_multilib_rng.cl",
    interface_file = "./test_multilib_rng.cpp",
    math_lib       = c("libkernel.cl", "./custom_helper.cl"),
    RNGkind        = "Mersenne-Twister"
  )
  out_mt <- fn_mt(1:5, scale = 0.05, seed = 42L)
  expect_equal(length(out_mt), 5L)
  expect_true(all(is.finite(out_mt)))
  expect_false(identical(out_xor, out_mt))

  ## C) mtime-Cache-Invalidierung prüfen (lokale Library ändern -> neues Verhalten)
  Sys.sleep(1.1)
  writeLines(c(
    "inline real custom_shift_normal(real x, real scale, RNG_PROTOTYPE) {",
    "    return x + (real)100.0f + scale * rnorm_internal((real)0.0f, (real)1.0f, RNG_01_ARGS);",
    "}"
  ), "./custom_helper.cl")

  fn_xor_updated <- oclFunction(
    signature      = methods::signature(x = "numeric", scale = "numeric", seed = "integer"),
    kernel_file    = "./test_multilib_rng.cl",
    interface_file = "./test_multilib_rng.cpp",
    math_lib       = c("libkernel.cl", "./custom_helper.cl"),
    RNGkind        = "Xorshift128"
  )
  out_updated <- fn_xor_updated(1:5, scale = 0.05, seed = 42L)
  expect_true(all(out_updated > 100.0))

  ## D) Dynamischer RNGkind-Wechsel in einem r*OCL-Wrapper (runifOCL)
  u_mt  <- runifOCL(10L, min = 0, max = 1, RNGkind = "Mersenne-Twister")
  u_xor <- runifOCL(10L, min = 0, max = 1, RNGkind = "Xorshift128")
  expect_equal(length(u_mt), 10L)
  expect_equal(length(u_xor), 10L)
  expect_true(all(u_mt >= 0 & u_mt <= 1))
  expect_true(all(u_xor >= 0 & u_xor <= 1))
}

