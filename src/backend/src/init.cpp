#include "backend/init.hpp"

#include "CLpp.hpp"

// 🚀 DER GLOBALE UNZERSTÖRBARE CORE:
// Dieses eine Objekt wird nur EINMALIG im RAM der R-Session geboren.
// Es hält den NVIDIA-Kontext und die Queue für ALLE Verteilungen permanent wach!

Device* global_opencl_device = nullptr;
bool opencl_bridge_established = false;


namespace backend {
  // Globale Variable bekannt machen
  extern std::string global_temporary_kernels_path;

  // 🚀 DIE ECHTE C-BRÜCKE FÜR WINDOWS, LINUX & MAC:
  extern "C" EXPORT void setKernelsPath(const std::string& path) {
    global_temporary_kernels_path = path;
    CLpp::instance().setKernelsPath(path);
  }

  // 🚀 DER UNZERSTÖRBARE GETTER-TUNNEL:
  // Diese freie Funktion exportiert das Symbol fehlerfrei über jede DLL-Grenze!
  extern "C"  EXPORT std::string getKernelsPathFromBackend() {
    return CLpp::instance().getKernelsPath();
  }
  extern "C" void activateDeviceWithMostFlops() {
    try {
      if (CLpp::instance().isInitialized()) {
        CLpp::instance().activateDeviceWithMostFlops();
      }
    } catch (...) {
      // Fehlgeschlagene Aktivierung im Docker-Container lautlos ignorieren
    }    
  }
  
  extern "C" void activateDeviceWithMostMemory() {
    try {
      if (CLpp::instance().isInitialized()) {
        CLpp::instance().activateDeviceWithMostMemory();
      }
    } catch (...) {
      // Fehlgeschlagene Aktivierung im Docker-Container lautlos ignorieren
    }    
  }
  
  extern "C" void activateDeviceWithIndex(int idx) {
    try {
      //      if (CLpp::instance().isInitialized()) {
        CLpp::instance().activateDeviceWithIndex(idx);
        //}
    } catch (...) {
      // Fehlgeschlagene Aktivierung im Docker-Container lautlos ignorieren
    }    
  }
  
  extern "C" void initCL() {
    //CLpp::instance().activateDeviceWithMostFlops();
    //CLpp::instance().info();
        if (!opencl_bridge_established) {
        // 🚀 LAZY-INITIALIZATION:
        // Erst JETZT scannt das Backend die Hardware absolut blockfrei!
        backend::CLpp::instance().setupDevices();

        // Das wache Gerät global im RAM spiegeln
        backend::sync_global_device();

        opencl_bridge_established = true;
    }
  }

    // 🚀 DIE LINKER-RETTUNG:
    // Wir greifen im Backend-Core direkt auf getActiveDevice() zu und weisen 
    // das fitte, wache Gerät mitsamt allen Flags der globalen Instanz zu!
    // Wir geben das wache Gerät per const-Referenz weiter. Das kostet 0 Taktzyklen
    // und verhindert jegliche verbotene Objekt-Duplizierung im RAM!
    extern "C" EXPORT const Device& getActiveDeviceFromBackend() {
      return CLpp::instance().getActiveDevice();
    }    

  // Holt die Synchronisations-Brücke für das gespiegelte Gerät zurück ins Binary!
  // EXPORT stellt sicher, dass das Symbol über jede Shared-Library-Grenze hinweg blitzt.
  extern "C" EXPORT void sync_global_device() {
      global_opencl_device = const_cast<Device*>(&CLpp::instance().getActiveDevice());

  }

}
