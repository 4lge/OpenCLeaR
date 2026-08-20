#pragma once

// Windows dll exports
// 🚀 DIE DYNAMISCHE WINDOWS-WEICHE:
#if defined(WIN32) || defined(_WIN32)
  #ifdef BUILDING_BACKEND_DLL
    #define EXPORT __declspec(dllexport)
  #elif defined(BUILDING_STATIC_R_PACKAGE)
    #define EXPORT // Statischer Einbau direkt in OpenCLeaR.dll: Kein Import/Export nötig!
  #else
    #define EXPORT __declspec(dllimport)
  #endif
#else
  #define EXPORT // Linux und Mac ignorieren das komplett
#endif
