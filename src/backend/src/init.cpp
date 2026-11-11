#include "backend/init.hpp"

#include "CLpp.hpp"

// This object exists only ONCE in the R session.
// It keeps the NVIDIA context and queue permanently awake.

Device* global_opencl_device = nullptr;
bool opencl_bridge_established = false;


namespace backend {
  // Make global variable known
  extern std::string global_temporary_kernel_path;

  //  c-bridge to kerenl path for windows, linux & mac:
  extern "C" EXPORT void setKernelsPath(const std::string& path) {
    global_temporary_kernel_path = path;
    CLpp::instance().setKernelsPath(path);
  }

  // This function exports the symbol across any DLL boundary without errors!
  EXPORT std::string getKernelsPathFromBackend() {
    return CLpp::instance().getKernelsPath();
  }
  extern "C" void activateDeviceWithMostFlops() {
    try {
      if (CLpp::instance().isInitialized()) {
        CLpp::instance().activateDeviceWithMostFlops();
      }
    } catch (...) {
      // Silently ignore failed activation in the Docker container
    }    
  }
  
  extern "C" void activateDeviceWithMostMemory() {
    try {
      if (CLpp::instance().isInitialized()) {
        CLpp::instance().activateDeviceWithMostMemory();
      }
    } catch (...) {
      // Silently ignore failed activation in the Docker container
    }    
  }
  
  extern "C" void activateDeviceWithIndex(int idx) {
    try {
        CLpp::instance().activateDeviceWithIndex(idx);
    } catch (...) {
      // Silently ignore failed activation in the Docker container
    }    
  }
  
  extern "C" void initCL() {
        if (!opencl_bridge_established) {
        // lazy initialization:
        // only now initialize the backend scan the hardware absolutely block-free!
        backend::CLpp::instance().setupDevices();

        // Mirror the awake device globally in RAM
        backend::sync_global_device();

        opencl_bridge_established = true;
    }
  }

    // We access getActiveDevice() directly in the backend core and assign 
    // the fit, awake device including all flags of the global instance!
    // We pass the awake device by const reference. This costs 0 clock cycles
    // and prevents any forbidden object duplication in RAM!
    EXPORT const Device& getActiveDeviceFromBackend() {
      return CLpp::instance().getActiveDevice();
    }    

  // Gets the synchronization bridge for the mirrored device back into the binary!
  // EXPORT ensures access across any shared library boundary (Windows).
  extern "C" EXPORT void sync_global_device() {
      global_opencl_device = const_cast<Device*>(&CLpp::instance().getActiveDevice());

  }

}
