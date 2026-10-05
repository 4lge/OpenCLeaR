##' Debug-Export für OpenCL RAM-Strings
##'
##' @param cl_code_string Der vollständig verkettete OpenCL-Quelltext-String
##' @param filepath Der Pfad, unter dem die Debug-Datei abgelegt werden soll (Default: "debug_kernel.cl")
##' @export
writeKernelToFile <- function(filepath = "debug_kernel.cl") {
    tryCatch({
        writeLines(GetKernelCode(), con = filepath)
        cat("💾 [DEBUG] Vollständiger OpenCL-Code erfolgreich exportiert nach:", filepath, "\n")
        cat("👉 Öffnen Sie diese Datei im Editor, um die Zeilennummern der Fehlermeldungen (z.B. <kernel>:21) zu prüfen!\n")
    }, error = function(e) {
        warning("Fehler beim Schreiben der Debug-Datei: ", e$message)
    })
}

