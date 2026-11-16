# tools/convert_nmath.R
#  FULLY AUTOMATIC NMATH -> OPENCL-C TRANSLATOR

# Make sure the opencltools package is available
library(opencltools)

c_code <- load_kernel_library("nmath")

# 1. Rigorously remove comments via Base-R Regex
clean_code <- gsub("/\\*.*?\\*/|//.*?(?=\\n|\\r|$)", "", c_code, perl = TRUE)

# 2. Place 'static inline' exactly before function headers that end in '{'
c_code_inline <- gsub(
  "(?m)^(\\s*)(?!inline|static|return|if|while|for\\b)([a-zA-Z0-9_]+[\\s\\*]+[a-zA-Z0-9_]+\\s*\\([^\\)]*\\)\\s*(?=\\{))",
  "\\1static inline \\2",
  clean_code,
  perl = TRUE
)

#3. Reformat floating point types to our portable real
c_code_inline <- gsub("\\bdouble(\\s*\\*+)?\\b", "real\\1", c_code_inline, perl = TRUE)
c_code_inline <- gsub("\\bfloat(\\s*\\*+)?\\b", "real\\1", c_code_inline, perl = TRUE)

# 4. Completely eliminate Windows carriage returns (\r).
c_code_inline <- gsub("\r", "", c_code_inline)

# Ensure target directory in package source exists
dir.create("src/backend/kernel", recursive = TRUE, showWarnings = FALSE)

# Write the result
writeLines(c_code_inline, "src/backend/kernel/nmath.cl")
cat(" [OpenCLeaR Build-Tools] nmath.cl successfully generated for OpenCL-C!\n")

