CMAKE_MINIMUM_REQUIRED(VERSION 3.10)
PROJECT(BACKEND CXX)

# Get the Rcpp minGW/gcc compilers in order to achieve highest degree of uniformity while users only have to install Rtools.
include(cmake/find_toolchain.cmake)
# ==============================================================================
#  some overrides for vintage mac OpenCL usage 
# ==============================================================================
if(APPLE)
    execute_process(COMMAND uname -r OUTPUT_VARIABLE DETECTED_DARWIN_VERSION)
    string(REGEX MATCH "^[0-9]+" DARWIN_MAJOR "${DETECTED_DARWIN_VERSION}")
    
    # Darwin 16 = macOS 10.12 Sierra | Darwin 15 = OS X 10.11 El Capitan
    if(DARWIN_MAJOR LESS_EQUAL 16)
        set(VINTAGE_STD "-std=c++14")
        if(DARWIN_MAJOR LESS_EQUAL 15)
            set(VINTAGE_STD "-std=c++11") # For OSX 10.11
        endif()
        
        message(STATUS " [OpenCLeaR] Override inherited R flags! Force compiler to use: ${VINTAGE_STD}")
        
        # Forces the compile options into the workflow and overwrites R's gnu++17!
        add_compile_options(${VINTAGE_STD})
    endif()
endif()

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
    GIT_TAG 67c9534eb5f529cdd190315ced7942aa33e2ba57
    SOURCE_DIR ${EXTERNAL_LIB_LOCATION}/OpenCL-Wrapper

    CONFIGURE_COMMAND ""  # Don't run cmake
    BUILD_COMMAND ""      # Don't build
    INSTALL_COMMAND ${CMAKE_COMMAND} -E copy ${EXTERNAL_LIB_LOCATION}/OpenCL-Wrapper/src/opencl.hpp ${EXTERNAL_LIB_LOCATION}/OpenCL-Wrapper/src/utilities.hpp ${EXTERNAL_LIB_LOCATION}/OpenCL-Wrapper/src/kernel.hpp ${CMAKE_CURRENT_BINARY_DIR}/local_install/include/

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
  ${CMAKE_SOURCE_DIR}/lib/OpenCL-Wrapper/src
  ${CMAKE_SOURCE_DIR}/lib/CLErrorLookup
  ${OpenCL_INCLUDE_DIRS}
)

# --- OpenCL search with intelligent Windows system check ---

if(WIN32)
  # We completely prohibit CMake from searching local OpenCL so that the package
  # is self-sufficient and compiles error-free on the CRAN-Win-Builder!
  set(OpenCL_FOUND FALSE)

  # We overwrite the include paths to the local Headers folder
  set(OpenCL_INCLUDE_DIRS ${CMAKE_SOURCE_DIR}/lib/OpenCL-Headers)
else()
  # The standard search remains active for Linux and macOS
  FIND_PACKAGE(OpenCL)
endif()


# --- Global Platform Switch ---
if(OpenCL_FOUND)
  message(STATUS "System OpenCL is in use: ${OpenCL_LIBRARIES}")
elseif(NOT OpenCL_FOUND)
  message(STATUS "System without OpenCL detected. Building local OpenCL ICD loader...")

  # Define location for the local loader
  set(OPENCL_LOADER_DIR ${CMAKE_SOURCE_DIR}/lib/OpenCL-ICD-Loader)

  # Add OpenCL ICD loader as ExternalProject
  ExternalProject_Add(OpenCL_ICD_Loader
      GIT_REPOSITORY https://github.com/KhronosGroup/OpenCL-ICD-Loader.git
      GIT_TAG v2024.10.24 
      SOURCE_DIR ${OPENCL_LOADER_DIR}
      DEPENDS OpenCL_Headers

      PATCH_COMMAND ${CMAKE_COMMAND} -DOPENCL_LOADER_DIR=${OPENCL_LOADER_DIR} -P "${CMAKE_CURRENT_SOURCE_DIR}/cmake/patch_adapter.cmake"
         COMMAND ${CMAKE_COMMAND} -DOPENCL_LOADER_DIR=${OPENCL_LOADER_DIR} -P "${CMAKE_CURRENT_SOURCE_DIR}/cmake/patch_envvars.cmake"

      CMAKE_ARGS 
        -DCMAKE_C_COMPILER=${CMAKE_C_COMPILER}
        -DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}
        -DCMAKE_MAKE_PROGRAM=${CMAKE_MAKE_PROGRAM}
        -DOPENCL_ICD_LOADER_HEADERS_DIR=${CMAKE_SOURCE_DIR}/lib/OpenCL-Headers
        -DOPENCL_ICD_LOADER_BUILD_SHARED_LIBS=ON
        -DCMAKE_INSTALL_PREFIX=${CMAKE_CURRENT_BINARY_DIR}/local_install
  )

  # Define target paths for the locally built library
  set(OpenCL_INCLUDE_DIRS ${CMAKE_SOURCE_DIR}/lib/OpenCL-Headers)
  
  if(WIN32)
    set(OpenCL_LIBRARIES "${CMAKE_CURRENT_BINARY_DIR}/OpenCL_ICD_Loader-prefix/src/OpenCL_ICD_Loader-build/OpenCL.dll")
    set(OpenCL_IMPLIB "${CMAKE_CURRENT_BINARY_DIR}/OpenCL_ICD_Loader-prefix/src/OpenCL_ICD_Loader-build/libOpenCL.dll.a")
  else()
    set(OpenCL_LIBRARIES "${CMAKE_CURRENT_BINARY_DIR}/OpenCL_ICD_Loader-prefix/src/OpenCL_ICD_Loader-build/libOpenCL.so")
  endif()

  # Create an artificial target so target_link_libraries doesn't fail
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
file(GLOB_RECURSE KERNELS "kernel/*.cpp")

# Define the path to the supplied OpenCL error
set(CLERROR_SRC "${EXTERNAL_LIB_LOCATION}/CLErrorLookup/CLErrorLookup/src")

# Forces CMake to fill in the missing files on the first "cmake ." Run to accept
# because they are only physically created during the subsequent Git clone!
set_source_files_properties(
    "${CLERROR_SRC}/cl_error_lookup.cpp"
    "${CLERROR_SRC}/get_error_info.cpp"
    PROPERTIES GENERATED TRUE
)

#  static switch for windows:
if(WIN32)
  # On Windows we build the backend as a static archive (.a)
  ADD_LIBRARY(BACKEND STATIC
      ${SOURCES}
      ${KERNELS}
      "${CLERROR_SRC}/cl_error_lookup.cpp"
      "${CLERROR_SRC}/get_error_info.cpp"
  )
else()
  # On Linux and macOS remains with the tried and tested shared library (.so/.dylib)
  ADD_LIBRARY(BACKEND SHARED
      ${SOURCES}
      ${KERNELS}
      "${CLERROR_SRC}/cl_error_lookup.cpp"
      "${CLERROR_SRC}/get_error_info.cpp"
  )  
endif()

# Forces GNU Make to finish loading the Git repo BEFORE the backend compiles!
add_dependencies(BACKEND CLErrorLookup)

if(WIN32)
  # for DLL_VAR to work in init.hpp:
  target_compile_definitions(BACKEND PRIVATE BUILDING_BACKEND_DLL)
endif()
# mandatory dependencies for all systems:
# The backend may only be built when all Git submodules are completely on the hard drive!
add_dependencies(BACKEND OpenCL_Headers OpenCL_CLHPP OpenCL_Wrapper CLErrorLookup)

# If local OpenCL in use, depend on it
if(NOT OpenCL_FOUND)
  add_dependencies(BACKEND OpenCL_ICD_Loader)
endif()

# The header includes go here
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
# We ALWAYS build the Khronos ICD loader natively under Windows,
# so that the R package links out-of-the-box on EVERY Windows PC (Nvidia, AMD, Intel)!
# ==============================================================================
if(WIN32)
  # 🚀 PERFEKTE WINDOWS-LINKAGE:
  # We link the backend directly to our artificial target "OpenCL_Local".
  # This already keeps the correct paths to libOpenCL.dll.a in the build folder!
   target_link_libraries(BACKEND
    PRIVATE
      OpenCL_Local
  )

  # The backend waits until the ICD loader has created the DLLs
  add_dependencies(BACKEND OpenCL_Local)

else()
  #  Linux and macOS continue to use the standard, flexible system detection
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

  # Default dependencies for Linux/Mac
  add_dependencies(BACKEND OpenCL_Headers OpenCL_CLHPP)
endif()

# ==============================================================================
#  step 5: mute backend cout output for unix systems (cran-safe)
# ==============================================================================
if(NOT WIN32)
  target_compile_definitions(BACKEND PRIVATE OPENCLEAR_NO_OUTPUT)
endif()

    
#######
# some OS-specific library name conventions here
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
  # Forces the GCC/MinGW compiler under Rtools to use absolutely strict
  # 64-bit stack alignment, matching System32 OpenCL.dll
  add_compile_options(-mstackrealign)
  add_definitions(-DCL_TARGET_OPENCL_VERSION=300)
endif()

#  automatic header export after build:
add_custom_command(TARGET BACKEND POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E make_directory "${CMAKE_CURRENT_SOURCE_DIR}/../../inst/include/backend"
    COMMAND ${CMAKE_COMMAND} -E copy "${CMAKE_CURRENT_SOURCE_DIR}/include/backend/CLpp.hpp" "${CMAKE_CURRENT_SOURCE_DIR}/../../inst/include/"
    COMMAND ${CMAKE_COMMAND} -E copy "${CMAKE_CURRENT_SOURCE_DIR}/include/backend/export.hpp" "${CMAKE_CURRENT_SOURCE_DIR}/../../inst/include/"
    COMMAND ${CMAKE_COMMAND} -E copy "${CMAKE_CURRENT_SOURCE_DIR}/include/backend/init.hpp" "${CMAKE_CURRENT_SOURCE_DIR}/../../inst/include/"
    COMMAND ${CMAKE_COMMAND} -E copy_directory "${CMAKE_CURRENT_BINARY_DIR}/local_install/include" "${CMAKE_CURRENT_SOURCE_DIR}/../../inst/include"
    COMMENT " Copy headers to inst/include folder for Rcpp..."
)

# ==============================================================================
# build automatic standalone compiler build (ocl_compiler)
# ==============================================================================

# 1. Declare path to compiler source
set(COMPILER_SOURCE_PATH "${EXTERNAL_LIB_LOCATION}/OpenCL-Wrapper/ocl_compiler.cpp")
set_source_files_properties(${COMPILER_SOURCE_PATH} PROPERTIES GENERATED TRUE)

#2. Declare the executable target
ADD_EXECUTABLE(ocl_compiler ${COMPILER_SOURCE_PATH})

# 2a. fix for older pocl systems:
# force cl2.hpp to stay at version 1.2 and block ghost flags like -cl-std=cl3.0!
TARGET_COMPILE_DEFINITIONS(ocl_compiler PRIVATE 
#    CL_HPP_TARGET_OPENCL_VERSION=120
#    CL_HPP_MINIMUM_OPENCL_VERSION=120
)
# 3. Base dependency (The source code must be there from Git)
ADD_DEPENDENCIES(ocl_compiler OpenCL_Headers OpenCL_CLHPP OpenCL_Wrapper)

# 4. the dynamic switch for driverless systems:
if(NOT OpenCL_FOUND)
    message(STATUS " [CMake JIT] cain ocl_compiler build to local ICD-Loader build...")
    
    # Force the compiler to wait until headers and loaders are ready in the build folder
    if(TARGET OpenCL_ICD_Loader)
        add_dependencies(ocl_compiler OpenCL_Headers OpenCL_CLHPP OpenCL_ICD_Loader)
    endif()

    # Add the include paths specifically to the local installation folder
    target_include_directories(ocl_compiler PRIVATE
        ${CMAKE_CURRENT_BINARY_DIR}/local_install/include
        ${CMAKE_CURRENT_BINARY_DIR}/src/OpenCL-Headers
        ${CMAKE_CURRENT_BINARY_DIR}/src/OpenCL-CLHPP/include
    )
endif()

# 5. Link general include paths (valid for all systems)
TARGET_INCLUDE_DIRECTORIES(ocl_compiler PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/include
    ${OpenCL_INCLUDE_DIRS}
    ${EXTERNAL_LIB_LOCATION}/OpenCL-Wrapper
    ${EXTERNAL_LIB_LOCATION}/OpenCL-Wrapper/src
    #  FIX: We tunnel the compiler directly to the local JIT installation folder!
    # Since this path is within the build directory, CMake evaluates it dynamically.
    ${CMAKE_CURRENT_BINARY_DIR}/local_install/include
    # As fallbacks for local builds:
    ${CMAKE_SOURCE_DIR}/lib/OpenCL-Headers
    ${CMAKE_SOURCE_DIR}/lib/OpenCL-CLHPP/include
)

# 6. Link linker directory and libraries
target_link_directories(ocl_compiler PRIVATE ${CMAKE_CURRENT_BINARY_DIR}/lib)

IF(WIN32)
  TARGET_LINK_LIBRARIES(ocl_compiler PRIVATE OpenCL_Local)
  ADD_DEPENDENCIES(ocl_compiler OpenCL_Local)
ELSE()
  if(OpenCL_FOUND)
    target_link_libraries(ocl_compiler PRIVATE ${OpenCL_LIBRARIES})
  else()
    target_link_libraries(ocl_compiler PRIVATE ${OpenCL_TARGET})
  endif()
ENDIF()

# 7.  automatic post-build export to inst/bin/
ADD_CUSTOM_COMMAND(TARGET ocl_compiler POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E make_directory "${CMAKE_CURRENT_SOURCE_DIR}/../../inst/bin"
    COMMAND ${CMAKE_COMMAND} -E copy $<TARGET_FILE:ocl_compiler> "${CMAKE_CURRENT_SOURCE_DIR}/../../inst/bin/"
    COMMENT "📦 Kompiliere ocl_compiler mit R-Toolchain und kopiere nach inst/bin/"
)

# Fix "not terminated with a newline" warnings in R CMD check
install(CODE "
  set(FILES_TO_FIX
    \"\${CMAKE_CURRENT_SOURCE_DIR}/inst/include/cl_error_lookup.hpp\"
    \"\${CMAKE_CURRENT_BINARY_DIR}/local_install/include/cl_error_lookup.hpp\"
    # If the external test files in the source code should also be corrected:
    \"\${CMAKE_CURRENT_SOURCE_DIR}/src/backend/lib/CLErrorLookup/CLErrorLookup/include/cl_error_lookup.hpp\"
    \"\${CMAKE_CURRENT_SOURCE_DIR}/src/backend/build/local_install/include/cl_error_lookup.hpp\"
    \"\${CMAKE_CURRENT_SOURCE_DIR}/src/backend/lib/OpenCL-CLHPP/tests/test_versions.cpp\"
  )

  foreach(FILE_PATH \${FILES_TO_FIX})
    if(EXISTS \"\${FILE_PATH}\")
      # Read file
      file(READ \"\${FILE_PATH}\" FILE_CONTENT)
      
      # If the file does not end with a newline, append one
      if(NOT \"\${FILE_CONTENT}\" MATCHES \"\\n$\")
        message(STATUS \"[OpenCLeaR] Append missing newline: \${FILE_PATH}\")
        file(APPEND \"\${FILE_PATH}\" \"\\n\")
      endif()
    endif()
  endforeach()
")


# Cleanup after completing all build and installation steps
install(CODE "
  message(STATUS \"[OpenCLeaR] Starting final cleanup for R CMD check...\")

  # 1. Define paths
  set(LOCAL_INSTALL_DIR \"\${CMAKE_CURRENT_BINARY_DIR}/local_install\")
  set(LIB_DIR \"\${CMAKE_CURRENT_SOURCE_DIR}/lib\")

  # 2. Remove temporary local_install folder
  if(IS_DIRECTORY \"\${LOCAL_INSTALL_DIR}\")
    message(STATUS \"[OpenCLeaR] Remove temporary folder: \${LOCAL_INSTALL_DIR}\")
    file(REMOVE_RECURSE \"\${LOCAL_INSTALL_DIR}\")
  endif()

  # 3. CRITICAL FOR CRAN: Remove all .git directories of ALL submodules in the source code folder
  set(GIT_DIRS
    \"\${LIB_DIR}/CLErrorLookup/.git\"
    \"\${LIB_DIR}/OpenCL-CLHPP/.git\"
    \"\${LIB_DIR}/OpenCL-Headers/.git\"
    \"\${LIB_DIR}/OpenCL-Wrapper/.git\"
    \"\${LIB_DIR}/OpenCL-ICD-Loader/.git\"
  )

  foreach(GIT_DIR \${GIT_DIRS})
    if(IS_DIRECTORY \"\${GIT_DIR}\")
      message(STATUS \"[OpenCLeaR] Remove Git backlog: \${GIT_DIR}\")
      file(REMOVE_RECURSE \"\${GIT_DIR}\")
    endif()
  endforeach()

  # 4. Delete the entire lib folder once everything is linked
  if(IS_DIRECTORY \"\${LIB_DIR}\")
    message(STATUS \"[OpenCLeaR] Entferne Drittanbieter-Quelltexte komplett aus dem Quellbaum...\")
    file(REMOVE_RECURSE \"\${LIB_DIR}\")
  endif()
")

