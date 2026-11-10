##' Gets detailed hardware information of the active OpenCL device
##'
##' @return An object of class \code{OpenCLDeviceInfo} with beautiful S3 output.
#' @export
GetActiveDeviceInfo <- function() {
  ## 1. Gets the internal hidden Rcpp function in a non-blocking manner
  info <- .GetActiveDeviceInfo_cpp()
  
  ## 2. add S3 class
  class(info) <- "OpenCLDeviceInfo"
  return(info)
}

##' Lists all OpenCL devices available in the system
##'
##' @return An object of class \code{OpenCLDeviceList} including compact S3 output.
##' @export
GetDeviceList <- function() {
  ## 1. Gets the internal hidden Rcpp function in a non-blocking manner
  df <- .GetDeviceList_cpp()
  
  ## 2. add S3 class (the DataFrame remains at the core!)
  class(df) <- c("OpenCLDeviceList", "data.frame")
  return(df)
}

##' Gets the kernel path currently set in the C++ backend
##' @return A string with the path
##' @export
GetKernelsPath <- function() {
  ## Uses the secure tunnel to the internal C++ function
  return(.GetKernelsPath_cpp())
}

##' S3 Print method for OpenCL device information
##' @method print OpenCLDeviceInfo
##' @export
print.OpenCLDeviceInfo <- function(x, ...) {
  ## protecte against uninitialsed state (lazy loading protection):
  if (x$Name == "" || x$Compute_Units == 0) {
    cat("|----------------,----------------------------------------------------------------|\n")
    cat("|  Note          | There is currently no OpenCL device activated.                 |\n")
    cat("|                | Please call 'ActivateDevice(<index>)' first!                   |\n")
    cat("|----------------'----------------------------------------------------------------|\n")
    return(invisible(x))
  }

  ## Auxiliary function for left-alignment (simulates C++ alignl)
  align_l <- function(text, width = 45) {
    ## the cleaning filter: Removes tabs and invisible driver ghosts!
    clean_txt <- trimws(as.character(text))
    clean_txt <- gsub("[^[:print:]]", "", clean_txt)
    
    if (nchar(clean_txt) >= width) return(substring(clean_txt, 1, width))
    paste0(clean_txt, paste(rep(" ", width - nchar(clean_txt)), collapse = ""))
  }
  ## Exactly one line per device!
  cat("|----------------.------------------------------------------------------------|\n")
  cat("| Device Index   | Device Name                                   | FP64       |\n")
  cat("|----------------+-----------------------------------------------+------------|\n")
  
  for (i in 1:nrow(x)) {
    idx_str   <- paste0(x$Index[i], " ")
    idx_pad   <- paste0(idx_str, paste(rep(" ", 15 - nchar(idx_str)), collapse = ""))
    name_pad <- align_l(x$Name[i], 45)
    fp64_str <- if (x$FP64_Capable[i]) "yes " else "no  "
    
    cat(paste0("|     ", idx_pad, "| ", name_pad, " | ", fp64_str, "       |\n"))
  }
  cat("|----------------'------------------------------------------------------------|\n")
  
  invisible(x) # Returns the object invisible
}

##' S3 print method for the OpenCL device list
##' @param x object of class \code{OpenclDeviceList}
##' @param ... additional arguments
##' @method print OpenCLDeviceList
##' @export
print.OpenCLDeviceList <- function(x, ...) {
  if (nrow(x) == 0) {
    cat("No OpenCL devices found in the system.\n")
    return(invisible(x))
  }

  ## Auxiliary function for left-alignment (simulates C++ alignl)
  align_l <- function(text, width = 45) {
    txt <- as.character(text)
    if (nchar(txt) >= width) return(substring(txt, 1, width))
    paste0(txt, paste(rep(" ", width - nchar(txt)), collapse = ""))
  }

  cat("|----------------.------------------------------------------------------------|\n")
  cat("| Device Index   | Device Name                                   | FP64       |\n")
  cat("|----------------+-----------------------------------------------+------------|\n")

  for (i in 1:nrow(x)) {
    ## The ID field has a fixed divider width of 10 characters ("|ID X    ")
    raw_idx <- as.character(x$Index[i])

    ## We calculate the exact padding for the spaces after the number:
    ## 11 characters total width - length of the digit
    padding_length <- 11 - nchar(raw_idx) 

    ## Safety net in case the ID becomes huge contrary to expectations
    if (padding_length < 1) padding_length <- 1

    ## Perfectly centered ID string without table shifting!
    idx_field <- paste0("    ", raw_idx, paste(rep(" ", padding_length), collapse = ""))

    name_pad <- align_l(x$Name[i], 45)
    fp64_str <- if (x$FP64_Capable[i]) "yes " else "no  "

    cat(paste0("| ", idx_field, "| ", name_pad, " | ", fp64_str, "       |\n"))
  }
  cat("|----------------'------------------------------------------------------------|\n")

  invisible(x)
}

