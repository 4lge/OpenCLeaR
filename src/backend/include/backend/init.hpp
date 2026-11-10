#pragma once

#include <string>
#ifndef PLUGIN
#include "backend/export.hpp"
#else
#include "export.hpp"
#endif
#include "opencl.hpp"

// the dynamic windows switch:
#if defined(WIN32) || defined(_WIN32)
  #ifdef BUILDING_BACKEND_DLL
    #define DLL_VAR __declspec(dllexport)
  #elif defined(BUILDING_STATIC_R_PACKAGE)
    #define DLL_VAR // Static installation directly in OpenCLeaR.dll: No import/export necessary!
  #else
    #define DLL_VAR __declspec(dllimport)
  #endif
#else
  #define DLL_VAR // Linux and Mac ignore this completely
#endif

// global singleton class:
extern "C" DLL_VAR Device* global_opencl_device;
extern "C" DLL_VAR bool opencl_bridge_established;

namespace backend {

	/**
	 * 	Attaches a kernel path to the static linkage OpenCL state singleton.
	 */
  extern "C" EXPORT void activateDeviceWithMostFlops();
  extern "C" EXPORT void activateDeviceWithMostMemory();
  extern "C" EXPORT void activateDeviceWithIndex(int idx);
  extern "C" EXPORT void setKernelsPath(const std::string& path);
  extern "C" EXPORT void initCL();
    // synchronization bridge for Rcpp
  extern "C" EXPORT void sync_global_device();
  EXPORT const Device& getActiveDeviceFromBackend(); // for plugiin use
}
