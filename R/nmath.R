##' Import nmath library for OpenCL
##'
##' Still experimental and untested!
#' @param target_dir target path, if NULL (default) 
#'    file.path(system.file(package = "OpenCLeaR"), "kernel") is used.
#' @export
ImportNmathKernels <- function(target_dir = NULL) {
  if (!requireNamespace("opencltools", quietly = TRUE)) {
    stop(paste0(
      " OpenCLeaR note:\n",
      "The 'opencltools' package is not installed on this system.\n",
      "nmath kernel import is not available.\n",
      "Please install 'opencltools' first if your hardware supports it."
    ), call. = FALSE)
  }
  
  cat(" Get nmath library and recalibrate types for GPU...\n")
  
  # Load code on the fly via the installed library
  c_code <- opencltools::load_kernel_library("nmath")
  
  # R mathlib functions cleaned by regex for OpenCL inline use
  clean_code <- gsub("/\\*.*?\\*/|//.*?(?=\\n|\\r|$)", "", c_code, perl = TRUE)
  
  c_code_inline <- gsub(
    "(?m)^(\\s*)(?!inline|static|return|if|while|for\\b)([a-zA-Z0-9_]+[\\s\\*]+[a-zA-Z0-9_]+\\s*\\([^\\)]*\\)\\s*(?=\\{))",
    "\\1static inline \\2",
    clean_code,
    perl = TRUE
  )
  
  c_code_inline <- gsub("\\bdouble(\\s*\\*+)?\\b", "real\\1", c_code_inline, perl = TRUE)
  c_code_inline <- gsub("\\bfloat(\\s*\\*+)?\\b", "real\\1", c_code_inline, perl = TRUE)
  c_code_inline <- gsub("\r", "", c_code_inline)
  
  if(is.null(target_dir)){
  # We write directly to the CURRENTLY INSTALLED package folder in the R system!
  installed_kernel_dir <- system.file("kernel", package = "OpenCLeaR")
  
  # If the directory is still missing when installed, create it on the fly
  if (installed_kernel_dir == "") {
    # Fallback determination of the installed library path
    installed_kernel_dir <- file.path(system.file(package = "OpenCLeaR"), "kernel")
    dir.create(installed_kernel_dir, recursive = TRUE, showWarnings = FALSE)
  }
  
  target_file <- file.path(installed_kernel_dir, "nmath.cl")
} else {
  target_file <- file.path(target_dir, "nmath.cl")
}
  writeLines(c_code_inline, target_file)
  
  cat(" [OpenCLeaR Runtime] nmath.cl successfully saved here:\n", target_file, "\n")
  return(TRUE)
}
