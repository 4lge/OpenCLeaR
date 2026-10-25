# tools/convert_nmath.R
# 🚀 VOLLAUTOMATISCHER NMATH -> OPENCL-C TRANSLATOR

# Sicherstellen, dass das opencltools-Paket oder deine interne Lade-Logik greift
library(opencltools)

c_code <- load_kernel_library("nmath")

# 1. Kommentare rigoros entfernen via Base-R Regex
clean_code <- gsub("/\\*.*?\\*/|//.*?(?=\\n|\\r|$)", "", c_code, perl = TRUE)

# 2. 'static inline' exakt vor Funktionsköpfe setzen, die auf '{' enden
c_code_inline <- gsub(
  "(?m)^(\\s*)(?!inline|static|return|if|while|for\\b)([a-zA-Z0-9_]+[\\s\\*]+[a-zA-Z0-9_]+\\s*\\([^\\)]*\\)\\s*(?=\\{))",
  "\\1static inline \\2",
  clean_code,
  perl = TRUE
)

# 3. Fließkommatypen bitscharf auf dein portables real umerziehen
c_code_inline <- gsub("\\bdouble(\\s*\\*+)?\\b", "real\\1", c_code_inline, perl = TRUE)
c_code_inline <- gsub("\\bfloat(\\s*\\*+)?\\b", "real\\1", c_code_inline, perl = TRUE)

# 4. Windows Wagenrückläufe (\r) restlos eliminieren
c_code_inline <- gsub("\r", "", c_code_inline)

# Zielverzeichnis im Paket-Source sicherstellen
dir.create("src/backend/kernel", recursive = TRUE, showWarnings = FALSE)

# Ergebnis wegschreiben
writeLines(c_code_inline, "src/backend/kernel/nmath.cl")
cat("🎉 [OpenCLeaR Build-Tools] nmath.cl erfolgreich für OpenCL-C generiert!\n")

