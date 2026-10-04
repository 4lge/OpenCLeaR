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
    GIT_TAG b29a44ec7bc9aee9db87a6b519a700b84602f182
    SOURCE_DIR ${EXTERNAL_LIB_LOCATION}/OpenCL-Wrapper

    CONFIGURE_COMMAND ""  # Don't run cmake
    BUILD_COMMAND ""      # Don't build
    INSTALL_COMMAND ${CMAKE_COMMAND} -E make_directory ${CMAKE_CURRENT_BINARY_DIR}/local_install/include/OpenCL-Wrapper
    COMMAND ${CMAKE_COMMAND} -E copy ${EXTERNAL_LIB_LOCATION}/OpenCL-Wrapper/src/kernel.hpp ${EXTERNAL_LIB_LOCATION}/OpenCL-Wrapper/src/opencl.hpp ${EXTERNAL_LIB_LOCATION}/OpenCL-Wrapper/src/utilities.hpp ${EXTERNAL_LIB_LOCATION}/OpenCL-Wrapper/src/kernel.hpp ${EXTERNAL_LIB_LOCATION}/OpenCL-Wrapper/src/cl_error_lookup.hpp  ${EXTERNAL_LIB_LOCATION}/OpenCL-Wrapper/src/get_error_info.hpp ${CMAKE_CURRENT_BINARY_DIR}/local_install/include/OpenCL-Wrapper/
)


# Include the external library headers in the lib folder
include_directories(
  ${CMAKE_SOURCE_DIR}/lib/OpenCL-Headers
  ${CMAKE_SOURCE_DIR}/lib/OpenCL-CLHPP/include
  ${CMAKE_CURRENT_BINARY_DIR}/local_install/include
  ${CMAKE_CURRENT_BINARY_DIR}/local_install/include/OpenCL-Wrapper
  ${OpenCL_INCLUDE_DIRS}
)

# --- OpenCL Suche mit intelligenter Windows-System-Prüfung ---

if(WIN32)
  # 🚀 Fix on Windows:
  # suppress OpenCL search and just use embedded OpenCL tree.
  # -> works also on machines without OpenCL e.g. as CRANs winbuilder.
  set(OpenCL_FOUND FALSE)

  # overwrite include paths with local ones:
  set(OpenCL_INCLUDE_DIRS ${CMAKE_SOURCE_DIR}/lib/OpenCL-Headers)
else()
  # Otherwise use standard search order for Linux und macOS
  FIND_PACKAGE(OpenCL)
endif()


# --- Globale Plattform-Weiche ---
if(OpenCL_FOUND)
  message(STATUS "System OpenCL used: ${OpenCL_LIBRARIES}")
elseif(NOT OpenCL_FOUND)
  message(STATUS "no OpenCL found, build local OpenCL-ICD-Loader...")

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
  # use static linkage on  Windows to reduce DLL stress
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



# 🚀 STATISCHE WEICHE FÜR WINDOWS:
if(WIN32)
  # Unter Windows bauen wir das Backend als statisches Archiv (.a)
  ADD_LIBRARY(BACKEND STATIC
      ${SOURCES}
      ${KERNELS}
  )
else()
  # Auf Linux bleibt es für den Dell-Server beim bewährten SHARED (.so)
  ADD_LIBRARY(BACKEND SHARED
      ${SOURCES}
      ${KERNELS}
  )
endif()



if(WIN32)
  # for DLL_VAR to work in init.hpp:
  target_compile_definitions(BACKEND PRIVATE BUILDING_BACKEND_DLL)
endif()
# ZWINGENDE ABHÄNGIGKEITEN FÜR ALLE SYSTEME:
# Das Backend darf erst bauen, wenn alle Git-Submodule vollständig auf der Festplatte liegen!
add_dependencies(BACKEND OpenCL_Headers OpenCL_CLHPP OpenCL_Wrapper)

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
    COMMAND ${CMAKE_COMMAND} -E copy "${CMAKE_CURRENT_SOURCE_DIR}/src/internal/CLpp.hpp" "${CMAKE_CURRENT_SOURCE_DIR}/../../inst/include/"
    COMMAND ${CMAKE_COMMAND} -E copy "${CMAKE_CURRENT_SOURCE_DIR}/include/backend/export.hpp" "${CMAKE_CURRENT_SOURCE_DIR}/../../inst/include/"
    COMMAND ${CMAKE_COMMAND} -E copy "${CMAKE_CURRENT_SOURCE_DIR}/include/backend/init.hpp" "${CMAKE_CURRENT_SOURCE_DIR}/../../inst/include/"
    COMMAND ${CMAKE_COMMAND} -E copy_directory "${CMAKE_CURRENT_BINARY_DIR}/local_install/include" "${CMAKE_CURRENT_SOURCE_DIR}/../../inst/include"
    COMMENT "📦 Kopiere Header in den inst/include Ordner für Rcpp..."
)
