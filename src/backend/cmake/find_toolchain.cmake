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

# 🚀 CRAN-STRATEGIE: Wir verbieten die nackte PATH-Suche komplett!
# Wir bauen den Pfad absolut bombensicher direkt aus der R_HOME-Umgebungsvariable.
if(DEFINED ENV{R_HOME})
    set(R_EXE "$ENV{R_HOME}/bin/R${_exe_suffix}")
    # Unter Windows/MinGW absichern, dass Backslashes CMake nicht verwirren
    file(TO_CMAKE_PATH "${R_EXE}" R_EXE)
else()
    # Fallback, falls R_HOME nicht gesetzt ist (Sicherheitsnetz)
    find_program(R_EXE NAMES R${_exe_suffix} PATHS ENV R_HOME PATH_SUFFIXES "bin" "bin/x64" NO_DEFAULT_PATH)
endif()
    
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
