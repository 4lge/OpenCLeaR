#pragma once

#include <string>
#ifndef PLUGIN
#include "backend/export.hpp"
#else
#include "export.hpp"
#endif
#include "opencl.hpp"

// 🚀 DIE DYNAMISCHE WINDOWS-WEICHE:
#if defined(WIN32) || defined(_WIN32)
  #ifdef BUILDING_BACKEND_DLL
    #define DLL_VAR __declspec(dllexport)
  #elif defined(BUILDING_STATIC_R_PACKAGE)
    #define DLL_VAR // Statischer Einbau direkt in OpenCLeaR.dll: Kein Import/Export nötig!
  #else
    #define DLL_VAR __declspec(dllimport)
  #endif
#else
  #define DLL_VAR // Linux und Mac ignorieren das komplett
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
  extern "C" EXPORT void activateDeviceWithID(int id);
  extern "C" EXPORT void setKernelsPath(const std::string& path);
  extern "C" EXPORT void initCL();
    // 🚀 NEU: Die Synchronisations-Brücke für Rcpp freischalten
  extern "C" EXPORT void sync_global_device();
  extern "C" EXPORT const Device& getActiveDeviceFromBackend(); // for plugiin use
}
