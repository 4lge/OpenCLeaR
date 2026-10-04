#include "CLpp.hpp"

#include <fstream>
#include <sstream>
#include <string>
#include <vector>
#include <iostream>



namespace backend {
  // global variables for initial setup phase
  std::string global_temporary_kernels_path = "";

  CLpp::CLpp() {
    // all work is done later via setupDevices()
    this->is_initialized = false;
  }

  CLpp::CLpp(bool dummy_mode) {
    // Macht absolut gar nichts. Verhindert jeden OpenCL-Aufruf.

  }

  bool CLpp::setupDevices() {
    this->kernels_path = global_temporary_kernels_path;
    try {
      this->activeDevice = Device(select_device_with_id(0L), this->collect_opencl_c_code());

      // check for virtual dummy device
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
    this->activeDevice = Device(dev, this->collect_opencl_c_code());
  }
  void CLpp::activateDeviceWithMostFlops(){
    this->activeDevice = Device(select_device_with_most_flops(), this->collect_opencl_c_code());
  }
  void CLpp::activateDeviceWithMostMemory(){
    this->activeDevice = Device(select_device_with_most_memory(), this->collect_opencl_c_code());
  }
  void CLpp::activateDeviceWithID(int id){
    this->activeDevice = Device(select_device_with_id(id), this->collect_opencl_c_code());
  }

  string CLpp::collect_opencl_c_code(){
    string opencl_c_lib = get_opencl_c_code(); // read string from kernel.hpp
    return opencl_c_lib;
  }

  bool CLpp::is_double(){
    return activeDevice.info.is_fp64_capable>=1;
  }

  void CLpp::activateDevice(int platform_id, int device_id){
  }

  void CLpp::setKernelsPath(const std::string& str) {
    std::lock_guard<std::mutex> lock(mutex);
    this->kernels_path = str;
  }

  std::string CLpp::getKernelsPath() const {
    std::lock_guard<std::mutex> lock(mutex);
    return this->kernels_path;
  }

  CLpp::~CLpp() {}

  CLpp& CLpp::instance() {
    static CLpp* inst = nullptr;
    if (inst == nullptr) {
      // 1. create empty structure
      inst = new CLpp();

      // 2. try to setup a device
      if (inst->setupDevices()) {
        // success
        std::cout << "OpenCL successfully initialised: device ready!" << std::endl;
      } else {
        // failure, delete it and replace with empty device
        delete inst;
        inst = new CLpp(true);
        std::cout << "OpenCL Fallback: dummy device used." << std::endl;
      }
    }
    return *inst;
  }
}
