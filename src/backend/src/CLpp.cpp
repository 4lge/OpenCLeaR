#include "CLpp.hpp"

#include <fstream>
#include <sstream>
#include <string>
#include <vector>
#include <iostream>



namespace backend {
  // Global variable to decouple the path at package startup
  std::string global_temporary_kernel_path = "";

  CLpp::CLpp() {
    // Default constructor remains empty because in case of success,
    //    setupDevices() does the work.
  }

  CLpp::CLpp(bool dummy_mode) {
    // Does absolutely nothing. Prevents any OpenCL call.
    this->is_initialized = false;
  }

  bool CLpp::setupDevices() {
    this->kernel_path = global_temporary_kernel_path;
    try {
      this->activeDevice = Device(select_device_with_id(0L));

      // Check for virtual dummy device
      if (this->activeDevice.info.name == "NULL device" || this->activeDevice.info.vendor == "Nobody") {
        this->is_initialized = false;
        return false;
      }

      this->is_initialized = true;
      return true;
    } catch (...) {
      this->is_initialized = false;
      return false;
    }
  }

  void CLpp::info() {
    //  std::cout << "name: " << this->activeDevice.info.name << std::endl;
    //  std::cout << "fp64: " << this->activeDevice.info.is_fp64_capable << std::endl;
  }

  void CLpp::activateDevice(Device_Info dev){
    this->activeDevice = Device(dev);
  }
  void CLpp::activateDeviceWithMostFlops(){
    this->activeDevice = Device(select_device_with_most_flops());
  }
  void CLpp::activateDeviceWithMostMemory(){
    this->activeDevice = Device(select_device_with_most_memory());
  }
  void CLpp::activateDeviceWithIndex(int id){
    this->activeDevice = Device(select_device_with_id(id));
  }

  string CLpp::collect_opencl_c_code(){
    string opencl_c_lib = get_opencl_c_code();
    return opencl_c_lib;
  }

  bool CLpp::is_double(){
    return activeDevice.info.is_fp64_capable>=1;
  }

  void CLpp::activate(int platform_id, int device_id){
  }

  // Brings the setter and the thread lock back into the physical source code!
  void CLpp::setKernelsPath(const std::string& str) {
    std::lock_guard<std::mutex> lock(mutex);
    this->kernel_path = str;
  }

  // Brings the getter and the thread lock back into the physical source code!
  std::string CLpp::getKernelsPath() const {
    std::lock_guard<std::mutex> lock(mutex);
    return this->kernel_path;
  }

  CLpp::~CLpp() {}

  CLpp& CLpp::instance() {
    static CLpp* inst = nullptr;
    if (inst == nullptr) {
      // 1. Create the object directly in normal mode
      inst = new CLpp();

      // 2. Try to activate the hardware.
      // If the internal wrapper calls instance() recursively, it sees
      // that inst != nullptr, and does not run into an infinite loop!
      if (inst->setupDevices()) {
        // SUCCESS (e.g. on your Linux with working OpenCL):
        // The object remains and is fully operational!
        // std::cout << "OpenCL initialized successfully: device ready!" << std::endl;
      } else {
        // ERROR CASE (e.g. in a driverless Docker container):
        // Delete the failed object and replace it with the safe dummy
        delete inst;
        inst = new CLpp(true);
        // std::cout << "OpenCL fallback enabled: Safe dummy object is used." << std::endl;
      }
    }
    return *inst;
  }


}
