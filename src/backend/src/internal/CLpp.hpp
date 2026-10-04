#pragma once

// private version of header

#include "opencl.hpp" // OpenCL Wrapper stuff
#include "backend/export.hpp" // Sicherstellen, dass EXPORT bekannt ist


#define CL_HPP_ENABLE_EXCEPTIONS
// #define CL_TARGET_OPENCL_VERSION 210
// #define CL_HPP_TARGET_OPENCL_VERSION 210
// #define CL_HPP_MINIMUM_OPENCL_VERSION 120
#include <CL/opencl.hpp>

#include <string>
#include <mutex>



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
    static EXPORT CLpp& instance();


    void activate(int platform_id, int device_id);
    
    // Gibt uns eine direkte Referenz auf Ihr fix und fertiges Wrapper-Gerät!
    inline const Device& getActiveDevice() const { return this->activeDevice; }

    void activateDeviceWithMostFlops();
    
    void activateDeviceWithMostMemory();

    void activateDeviceWithID(int id);

    void activateDevice(int, int);
    
    void activateDevice(Device_Info dev);
    
    void info();


    string collect_opencl_c_code();
    
    bool is_double();

    // attaches the resources path
    void setKernelsPath(const std::string& str);
    // retrieves the resources path
    std::string getKernelsPath() const;
    
    void initCL();
    
    // Build a program from a kernel file
    cl::Program get_program(const std::string& filepath) const;
    
    bool isInitialized() const { return is_initialized; }

    bool setupDevices(); // Lagert die Initialisierung aus

  private:
    // Initializer runs the typical init code for your external library
    CLpp();
    // Destructor cleans up the external library state
    ~CLpp();

    
    CLpp(bool dummy_mode); // Neuer Konstruktor für den sicheren Modus
    bool is_initialized = false; // Flag für den Status


    Device activeDevice;
    
    // thread safe singleton
    CLpp(const CLpp&) = delete;
    CLpp& operator=(const CLpp&) = delete;

    std::string kernels_path;

    // CL constants:
    /*
    std::vector<cl::Platform> platforms;
    std::vector<cl::Device> devices;    
    cl::Device best_device;
    cl::Platform best_platform;
    cl::Device active_device;
    cl::Platform active_platform;
    cl::Context context;
    cl::CommandQueue queue;

    // attached resource path
    std::string kernels_path;
    */
    // thread safety
    mutable std::mutex mutex;
  };

}
