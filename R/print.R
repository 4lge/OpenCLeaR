##' S3 Print method for OpenCL device information
##' @param x An object of the OpenCLDeviceInfo class
##' @param ... more arguments 
##' @method print OpenCLDeviceInfo
##' @export
print.OpenCLDeviceInfo <- function(x, ...) {
  ## Auxiliary function intercepts empty or corrupt fields indestructibly!
  align_l <- function(text, width = 58) {
    if (is.null(text) || length(text) == 0 || is.na(text)) {
      txt <- "NA"
    } else {
    txt <- as.character(text)
    }
    if (nchar(txt) >= width) return(substring(txt, 1, width))
    paste0(txt, paste(rep(" ", width - nchar(txt)), collapse = ""))
  }
  
  ## Format memory readable (RAM vs VRAM)
  mem_type <- if (isTRUE(x$Uses_RAM)) "RAM" else "VRAM"
  
  cat("|----------------.------------------------------------------------------------|\n")
  cat(paste0("| Device Index   | ", align_l(x$Index), " |\n"))
  cat(paste0("| Platform ID    | ", align_l(x$Platform_ID), " |\n")) 
  cat(paste0("| Device ID      | ", align_l(x$Device_ID), " |\n"))
  cat(paste0("| Device Name    | ", align_l(x$Name), " |\n"))
  cat(paste0("| Device Vendor  | ", align_l(x$Vendor), " |\n"))
  cat(paste0("| Device Driver  | ", align_l(paste0(x$Driver_Version, " (", x$OS, ")")), " |\n"))
  cat(paste0("| OpenCL Version | ", align_l(x$OpenCL_Version), " |\n"))
  
  ## Output calculated cores and TFLOPs formatted
  compute_str <- paste0(x$Compute_Units, " at ", x$Clock_MHz, " MHz (", x$Cores, " cores, ", round(x$TFLOPs, 3), " TFLOPs/s)")
  cat(paste0("| Compute Units  | ", align_l(compute_str), " |\n"))
  
  ## Cache and memory limits
  mem_str <- paste0(x$Memory_MB, " MB ", mem_type, ", ", x$Global_Cache_KB, " KB global / ", x$Local_Cache_KB, " KB local")
  cat(paste0("| Memory, Cache  | ", align_l(mem_str), " |\n"))
  
  buf_str <- paste0(x$Max_Buffer_MB, " MB global, ", x$Max_Constant_KB, " KB constant")
  cat(paste0("| Buffer Limits  | ", align_l(buf_str), " |\n"))
  
  ## FP64 ability
  cat(paste0("| FP64 capable   | ", align_l(if (isTRUE(x$FP64_Capable)) "TRUE" else "FALSE"), " |\n"))
  cat("|----------------'------------------------------------------------------------|\n")
  
  invisible(x) 
}
