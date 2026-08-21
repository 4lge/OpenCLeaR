CMAKE_MINIMUM_REQUIRED(VERSION 3.10)
PROJECT(BACKEND CXX)

# Get the Rcpp minGW/gcc compilers in order to achieve highest degree of uniformity while users only have to install Rtools.
include(cmake/find_toolchain.cmake)

# Pull the dependencies from Github
include(ExternalProject)
set(EXTERNAL_LIB_LOCATION ${CMAKE_SOURCE_DIR}/lib)
ExternalProject_Add(OpenCL_Headers
    GIT_REPOSITORY https://github.com/KhronosGroup/OpenCL-Headers.git
    GIT_TAG b79b358ff6b9998d3fc65a5f55083db3d651d55d
    SOURCE_DIR ${EXTERNAL_LIB_LOCATION}/OpenCL-Headers

    CONFIGURE_COMMAND ""  # Don't run cmake
    BUILD_COMMAND ""      # Don't build
    INSTALL_COMMAND ${CMAKE_COMMAND} -E copy_directory ${EXTERNAL_LIB_LOCATION}/OpenCL-Headers/CL ${CMAKE_CURRENT_BINARY_DIR}/local_install/include/CL

)
ExternalProject_Add(OpenCL_CLHPP
    GIT_REPOSITORY https://github.com/KhronosGroup/OpenCL-CLHPP.git
    GIT_TAG 2a608428f725cad7903ef55e1ce5b995895838f5
    SOURCE_DIR ${EXTERNAL_LIB_LOCATION}/OpenCL-CLHPP

    CONFIGURE_COMMAND ""  # Don't run cmake
    BUILD_COMMAND ""      # Don't build
    INSTALL_COMMAND ${CMAKE_COMMAND} -E copy_directory ${EXTERNAL_LIB_LOCATION}/OpenCL-CLHPP/include/CL ${CMAKE_CURRENT_BINARY_DIR}/local_install/include/CL

)
execute_process(COMMAND ${CMAKE_COMMAND} -E make_directory "${CMAKE_CURRENT_BINARY_DIR}/local_install/include/")
ExternalProject_Add(OpenCL_Wrapper
    GIT_REPOSITORY https://github.com/4lge/OpenCL-Wrapper.git
    GIT_TAG b878e52154065267b67d85e65494bed28381e1ea
    SOURCE_DIR ${EXTERNAL_LIB_LOCATION}/OpenCL-Wrapper

    CONFIGURE_COMMAND ""  # Don't run cmake
    BUILD_COMMAND ""      # Don't build
    INSTALL_COMMAND ${CMAKE_COMMAND} -E make_directory ${CMAKE_CURRENT_BINARY_DIR}/local_install/include/OpenCL-Wrapper
    COMMAND ${CMAKE_COMMAND} -E copy ${EXTERNAL_LIB_LOCATION}/OpenCL-Wrapper/src/kernel.hpp ${EXTERNAL_LIB_LOCATION}/OpenCL-Wrapper/src/opencl.hpp ${EXTERNAL_LIB_LOCATION}/OpenCL-Wrapper/src/utilities.hpp ${EXTERNAL_LIB_LOCATION}/OpenCL-Wrapper/src/kernel.hpp ${CMAKE_CURRENT_BINARY_DIR}/local_install/include/OpenCL-Wrapper/
)

ExternalProject_Add(CLErrorLookup
    GIT_REPOSITORY https://github.com/otto-link/CLErrorLookup.git
    GIT_TAG 27adbb9217e2a9e31b08fe32acc21df9d2b53e84
    SOURCE_DIR ${EXTERNAL_LIB_LOCATION}/CLErrorLookup

    CONFIGURE_COMMAND ""  # Don't run cmake
    BUILD_COMMAND ""      # Don't build
    
    # 🚀 NUR NOCH DIE HEADER KOPIEREN (Das läuft zu 100% fehlerfrei durch):
    INSTALL_COMMAND ${CMAKE_COMMAND} -E copy_directory ${EXTERNAL_LIB_LOCATION}/CLErrorLookup/CLErrorLookup/include ${CMAKE_CURRENT_BINARY_DIR}/local_install/include/
)

# Include the external library headers in the lib folder
include_directories(
  ${CMAKE_SOURCE_DIR}/lib/OpenCL-Headers
  ${CMAKE_SOURCE_DIR}/lib/OpenCL-CLHPP/include
  ${CMAKE_SOURCE_DIR}/lib/CLErrorLookup
  ${CMAKE_CURRENT_BINARY_DIR}/local_install/include
  ${CMAKE_CURRENT_BINARY_DIR}/local_install/include/OpenCL-Wrapper
  ${OpenCL_INCLUDE_DIRS}
)

# --- OpenCL Suche mit intelligenter Windows-System-Prüfung ---

if(WIN32)
  # 🚀 WINDOWS-AUTARKIE-TURBO:
  # Wir verbieten CMake die lokale NVIDIA-Suche komplett, damit das Paket
  # autark wird und auf dem CRAN-Win-Builder fehlerfrei kompiliert!
  set(OpenCL_FOUND FALSE)

  # Wir überschreiben die Include-Pfade auf den lokalen Headers-Ordner
  set(OpenCL_INCLUDE_DIRS ${CMAKE_SOURCE_DIR}/lib/OpenCL-Headers)
else()
  # Für Linux und macOS bleibt die bewährte Standardsuche aktiv
  FIND_PACKAGE(OpenCL)
endif()


# --- Globale Plattform-Weiche ---
if(OpenCL_FOUND)
  message(STATUS "System OpenCL wird verwendet: ${OpenCL_LIBRARIES}")
elseif(NOT OpenCL_FOUND)
  message(STATUS "Windows Sandbox/Docker oder treiberloses Linux erkannt. Baue lokalen OpenCL-ICD-Loader...")

  # Speicherort für den lokalen Loader definieren
  set(OPENCL_LOADER_DIR ${CMAKE_SOURCE_DIR}/lib/OpenCL-ICD-Loader)

  # OpenCL-ICD-Loader als ExternalProject hinzufügen
  ExternalProject_Add(OpenCL_ICD_Loader
      GIT_REPOSITORY https://github.com/KhronosGroup/OpenCL-ICD-Loader.git
      GIT_TAG v2024.10.24 
      SOURCE_DIR ${OPENCL_LOADER_DIR}
      DEPENDS OpenCL_Headers
      
      CMAKE_ARGS 
        -DCMAKE_C_COMPILER=${CMAKE_C_COMPILER}
        -DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}
        -DCMAKE_MAKE_PROGRAM=${CMAKE_MAKE_PROGRAM}
        -DOPENCL_ICD_LOADER_HEADERS_DIR=${CMAKE_SOURCE_DIR}/lib/OpenCL-Headers
        -DOPENCL_ICD_LOADER_BUILD_SHARED_LIBS=ON
        -DCMAKE_INSTALL_PREFIX=${CMAKE_CURRENT_BINARY_DIR}/local_install
  )

  # Zielpfade für die lokal gebaute Bibliothek definieren
  set(OpenCL_INCLUDE_DIRS ${CMAKE_SOURCE_DIR}/lib/OpenCL-Headers)
  
  if(WIN32)
    set(OpenCL_LIBRARIES "${CMAKE_CURRENT_BINARY_DIR}/OpenCL_ICD_Loader-prefix/src/OpenCL_ICD_Loader-build/OpenCL.dll")
    set(OpenCL_IMPLIB "${CMAKE_CURRENT_BINARY_DIR}/OpenCL_ICD_Loader-prefix/src/OpenCL_ICD_Loader-build/libOpenCL.dll.a")
  else()
    set(OpenCL_LIBRARIES "${CMAKE_CURRENT_BINARY_DIR}/OpenCL_ICD_Loader-prefix/src/OpenCL_ICD_Loader-build/libOpenCL.so")
  endif()

  # Erstelle ein künstliches Target, damit target_link_libraries nicht fehlschlägt
  add_library(OpenCL_Local SHARED IMPORTED GLOBAL)
  
  if(WIN32)
    set_target_properties(OpenCL_Local PROPERTIES
      IMPORTED_LOCATION "${OpenCL_LIBRARIES}"
      IMPORTED_IMPLIB "${OpenCL_IMPLIB}"
    )
  else()
    set_target_properties(OpenCL_Local PROPERTIES
      IMPORTED_LOCATION "${OpenCL_LIBRARIES}"
      IMPORTED_NO_SONAME TRUE
    )
  endif()
  
  add_dependencies(OpenCL_Local OpenCL_ICD_Loader)
  set(OpenCL_TARGET "OpenCL_Local")
endif()


# Make a shared library
file(GLOB_RECURSE SOURCES "src/*.cpp")
file(GLOB_RECURSE KERNELS "kernels/*.cpp")

# Pfad zum mitgelieferten OpenCL Error definieren
set(CLERROR_SRC "${EXTERNAL_LIB_LOCATION}/CLErrorLookup/CLErrorLookup/src")

# 🚀 DIE CONFIGURATION-RETTUNG (Generated-Flags):
# Zwingt CMake, die fehlenden Dateien beim ersten "cmake ." Lauf zu akzeptieren,
# da sie erst während des darauffolgenden Git-Clones physisch entstehen!
set_source_files_properties(
    "${CLERROR_SRC}/cl_error_lookup.cpp"
    "${CLERROR_SRC}/get_error_info.cpp"
    PROPERTIES GENERATED TRUE
)

# 🚀 STATISCHE WEICHE FÜR WINDOWS:
if(WIN32)
  # Unter Windows bauen wir das Backend als statisches Archiv (.a)
  ADD_LIBRARY(BACKEND STATIC
      ${SOURCES}
      ${KERNELS}
      "${CLERROR_SRC}/cl_error_lookup.cpp"
      "${CLERROR_SRC}/get_error_info.cpp"
  )
else()
  # Auf Linux bleibt es für den Dell-Server beim bewährten SHARED (.so)
  ADD_LIBRARY(BACKEND SHARED
      ${SOURCES}
      ${KERNELS}
      "${CLERROR_SRC}/cl_error_lookup.cpp"
      "${CLERROR_SRC}/get_error_info.cpp"
  )
endif()


# Zwingt GNU Make, das Git-Repo fertig zu laden, BEVOR das Backend kompiliert!
add_dependencies(BACKEND CLErrorLookup)

if(WIN32)
  # for DLL_VAR to work in init.hpp:
  target_compile_definitions(BACKEND PRIVATE BUILDING_BACKEND_DLL)
endif()
# ZWINGENDE ABHÄNGIGKEITEN FÜR ALLE SYSTEME:
# Das Backend darf erst bauen, wenn alle Git-Submodule vollständig auf der Festplatte liegen!
add_dependencies(BACKEND OpenCL_Headers OpenCL_CLHPP OpenCL_Wrapper CLErrorLookup)

# If local OpenCL in use, depend on it
if(NOT OpenCL_FOUND)
  add_dependencies(BACKEND OpenCL_ICD_Loader)
endif()

# The header includes go here
# Leave the two /include and /src/internal ones in here; the rest can be altered.
target_include_directories(BACKEND
  PUBLIC 
    ${CMAKE_CURRENT_SOURCE_DIR}/include
	PRIVATE
		${CMAKE_CURRENT_SOURCE_DIR}/src/internal
		${OpenCL_INCLUDE_DIRS}
    ${CMAKE_SOURCE_DIR}/lib/OpenCL-Headers
    ${CMAKE_SOURCE_DIR}/lib/OpenCL-CLHPP/include
    ${CMAKE_SOURCE_DIR}/lib/CLErrorLookup/CLErrorLookup/include
)

# ------------------------------------------------------------------------------
# Linkage against your binaries
# ==============================================================================
# 🚀 DER UNZERSTÖRBARRE WINDOWS-PORTABILITÄTS-CORE:
# Unter Windows bauen wir den Khronos-ICD-Loader IMMER nativ mit,
# damit das R-Paket auf JEDEM Windows-PC (Nvidia, AMD, Intel) out-of-the-box linkt!
# ==============================================================================
if(WIN32)
  # 🚀 PERFEKTE WINDOWS-LINKAGE:
  # Wir verlinken das Backend direkt mit Ihrem künstlichen Target "OpenCL_Local".
  # Dieses hält bereits die korrekten Pfade zur libOpenCL.dll.a im Build-Ordner!
   target_link_libraries(BACKEND
    PRIVATE
      OpenCL_Local
  )

  # Das Backend wartet, bis der ICD-Loader die DLLs erzeugt hat
  add_dependencies(BACKEND OpenCL_Local)

else()
  # 🐧 Linux und macOS nutzen weiterhin die standardmäßige, flexible System-Erkennung
  if(OpenCL_FOUND)
    target_link_libraries(BACKEND
      PRIVATE
        ${OpenCL_LIBRARIES}
        OpenCL::OpenCL
    )
  else()
    target_link_libraries(BACKEND
      PRIVATE
        ${OpenCL_TARGET}
    )
  endif()

  # Standard-Abhängigkeiten für Linux/Mac
  add_dependencies(BACKEND OpenCL_Headers OpenCL_CLHPP)
endif()

# some OS-specific library name conventions here; just leave as is as it would change the way Rcpp's Makefile needs to look.
if(WIN32)
  SET_TARGET_PROPERTIES(BACKEND PROPERTIES
    OUTPUT_NAME "BACKEND"
    PREFIX ""
  )
endif()
# add install name on macOS
if(APPLE)
  SET_TARGET_PROPERTIES(BACKEND PROPERTIES
    MACOSX_RPATH ON
    INSTALL_NAME_DIR "@rpath"
  )
endif()


if(WIN32)
  # Zwingt den GCC/MinGW-Compiler unter Rtools zu absolut striktem
  # 64-Bit-Stack-Alignment, passend zur System32 OpenCL.dll
  add_compile_options(-mstackrealign)
  add_definitions(-DCL_TARGET_OPENCL_VERSION=300)
endif()

# Ganz unten in Ihrer src/backend/CMakeLists.txt:
# 🚀 AUTOMATISCHER HEADER-EXPORT NACH DEM BUILD:
add_custom_command(TARGET BACKEND POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E make_directory "${CMAKE_CURRENT_SOURCE_DIR}/../../inst/include/backend"
    COMMAND ${CMAKE_COMMAND} -E copy "${CMAKE_CURRENT_SOURCE_DIR}/src/internal/CL_context.hpp" "${CMAKE_CURRENT_SOURCE_DIR}/../../inst/include/"
    COMMAND ${CMAKE_COMMAND} -E copy "${CMAKE_CURRENT_SOURCE_DIR}/include/backend/export.hpp" "${CMAKE_CURRENT_SOURCE_DIR}/../../inst/include/"
    COMMAND ${CMAKE_COMMAND} -E copy "${CMAKE_CURRENT_SOURCE_DIR}/include/backend/init.hpp" "${CMAKE_CURRENT_SOURCE_DIR}/../../inst/include/"
    COMMAND ${CMAKE_COMMAND} -E copy_directory "${CMAKE_CURRENT_BINARY_DIR}/local_install/include" "${CMAKE_CURRENT_SOURCE_DIR}/../../inst/include"
    COMMENT "📦 Kopiere Header in den inst/include Ordner für Rcpp..."
)
