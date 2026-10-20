##' Export OpenCL code for debugging purposes. 
##'
##' @param filepath path where to save it (default: "debug_kernel.cl")
##' @export
writeKernelToFile <- function(filepath = "debug_kernel.cl") {
    tryCatch({
        writeLines(GetKernelCode(), con = filepath)
        cat(" [DEBUG] full generated OpenCL code exported to:", filepath, "\n")
    }, error = function(e) {
        warning("error writing OpenCL code to file: ", e$message)
    })
}

