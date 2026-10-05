######################################################################
#
#   CMake script to retrieve the C, CXX Compilers and MAKE from Rcpp.
#
#   This ensures:
#       1. That the C backend and the Rcpp library are both built
#           using the same toolchain.
#       2. That the toolchain is actually complete and found as Rcpp
#           and Rtools is installed.
#
######################################################################
# Definiere das Betriebssystem-spezifische Suffix für ausführbare Dateien
if(WIN32)
    set(_exe_suffix ".exe")
else()
    set(_exe_suffix "")
endif()

# Suche nach dem R-Programm mittels Umgebungsvariablen
find_program(R_EXE
    NAMES R${_exe_suffix}
    PATHS 
        ENV PATH                  # Durchsucht die normale System-PATH-Variable
        ENV R_HOME                # Nutzt eine optionale, explizite R_HOME-Variable
    PATH_SUFFIXES "bin" "bin/x64" # Typische Unterordner, in denen R liegt
)

# Überprüfe, ob das Programm erfolgreich gefunden wurde
if(R_EXE)
    message(STATUS "R ausführbare Datei gefunden: ${R_EXE}")
else()
    message(SEND_ERROR "R ausführbare Datei konnte nicht gefunden werden.")
endif()

execute_process (
	COMMAND ${R_EXE} --slave -e "cat(Sys.which('g++'))"
    OUTPUT_VARIABLE CMAKE_CXX_COMPILER
    OUTPUT_STRIP_TRAILING_WHITESPACE
)

execute_process (
	COMMAND ${R_EXE} --slave -e "cat(Sys.which('gcc'))"
    OUTPUT_VARIABLE CMAKE_C_COMPILER
    OUTPUT_STRIP_TRAILING_WHITESPACE
)

execute_process (
	COMMAND ${R_EXE} --slave -e "cat(Sys.which('make'))"
    OUTPUT_VARIABLE CMAKE_MAKE_PROGRAM
    OUTPUT_STRIP_TRAILING_WHITESPACE
)
