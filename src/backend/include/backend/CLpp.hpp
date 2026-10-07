#pragma once

#include <string> 
using std::string;

// minimal public version of header, omit all OpenCL Wrapper stuff here (opencl.hpp)

namespace backend {


  /**
   * 	A singleton class managing the external library state (in this case OpenCL).
   * 	
   *   interface to OpenCL-Wrapper
   *
   */
  class CLpp {
  public:
    // gets the static linkage CL state
    static CLpp& instance();


    void activate(int platform_id, int device_id);
    
    // Device getActiveDevice();

    void activateDeviceWithMostFlops();
    
    void activateDeviceWithMostMemory();

    void activateDeviceWithIndex(int idx);

    //void activateDevice(Device_Info dev);
    
    void info();

    string collect_opencl_c_code();
    
    bool is_double();

    void setKernelsPath(const std::string& str);
    std::string getKernelsPath() const;


    void initCL();
    
    
    bool isInitialized() const { return is_initialized; }

  private:
    // Initializer runs the typical init code for your external library
    CLpp();
    // Destructor cleans up the external library state
    ~CLpp();

    
    CLpp(bool dummy_mode); // Neuer Konstruktor für den sicheren Modus
    bool is_initialized = false; // Flag für den Status

    bool setupDevices(); // Lagert die Initialisierung aus

    // Device activeDevice;
    
    // thread safe singleton
    CLpp(const CLpp&) = delete;
    CLpp& operator=(const CLpp&) = delete;

    std::string kernels_path;

  };
}
