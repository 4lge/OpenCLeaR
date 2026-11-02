#include <Rcpp.h>
#include "backend/init.hpp"
#include "backend/CLpp.hpp"
#include "utilities.hpp"
#include <thread>
#include <chrono>
#include <atomic>
#include <R.h> // needed for R_CheckUserInterrupt()
#include "device.hpp"


using namespace Rcpp;

// declare this function from init.cpp:
namespace backend {
  std::string getKernelsPathFromBackend();
}

//' Activate OpenCL devive with maximum FLOPS
//'
//' Automatically chooses the device with maximum FLOPS.
//' @note This is the default activation method.
//' @export
// [[Rcpp::export]]
void ActivateDeviceWithMostFlops() {
  backend::activateDeviceWithMostFlops();
  backend::sync_global_device();
}

//' Activate OpenCL devive with maximum memory
//'
//' Automatically chooses the device with maximum memory.
//' @export
// [[Rcpp::export]]
void ActivateDeviceWithMostMemory() {
  backend::activateDeviceWithMostMemory();
  backend::sync_global_device();
}

//' Activate OpenCL devive by Index
//' @param idx index of device, all devices will be shown on load ofthe
//'     library. counts start from 0.
//' @export
// [[Rcpp::export(name = "ActivateDeviceWithIndex_Native")]]
void ActivateDeviceWithIndex_Native(int idx) {
  // // Preparation for clean driver change 
  // global_opencl_device = nullptr;

  // The C++ backend switches hardware without any hangups
  backend::CLpp::instance().activateDeviceWithIndex(idx);

  // synchronizes the global C pointer for Rcpp to the new device address
  global_opencl_device = const_cast<Device*>(&backend::getActiveDeviceFromBackend());
}

//' OpenCL asynchronous device activation routine to break Windows WDDM context lock
//'
//' @param idx Integer index of the device to activate asynchronously.
//' @export
// [[Rcpp::export(name = "ActivateDeviceWithIndex_Async", rng = FALSE)]]
bool ActivateDeviceWithIndex_Async(int idx) {
  std::atomic<bool> is_done(false);
  std::atomic<bool> success(false);
  // start in a separate thread:
  std::thread cl_activate_thread([&is_done, &success, idx]() {
    try {
      backend::activateDeviceWithIndex(idx);

      success = true;
    } catch (...) {
      success = false;
    }
    is_done = true; // Signal R main thread that the device is activated
  });

  // blocking free main loop in the main thread
  // Keeps R alive and overrides the Windows WDDM lock!
  while (!is_done) {
    std::this_thread::sleep_for(std::chrono::milliseconds(5));

#ifdef _WIN32
    // Force Windows to change threads before the system freezes!
    R_CheckUserInterrupt();
#endif
  }

  // catch the  thread cleanly again
  if (cl_activate_thread.joinable()) {
    cl_activate_thread.join();
  }
  //  Safely access globa device pointer
  if (success) {
    global_opencl_device = const_cast<Device*>(&backend::getActiveDeviceFromBackend());
  }
  return success;
}

//' OpenCL initialization routine
//'
//' to be called via onLoad mechanism.
//' @export
// [[Rcpp::export]]
bool InitCL() {
  // If the bridge is already active, we immediately block any additional init trials.
  // This prevents the 200 second wait lock under Windows!
  if (opencl_bridge_established && global_opencl_device != nullptr) {
    return true;
  }

  std::atomic<bool> is_done(false);
  std::atomic<bool> success(false);

  // We fork initialization out of the R scope.
  std::thread cl_init_thread([&]() {
    try {
      if (!opencl_bridge_established) {
        backend::initCL();
      }
      success = true;
    } catch (...) {
      success = false;
    }
    is_done = true;
  });

  // Keeps R awake and break the WDDM lock:
  while (!is_done) {
    std::this_thread::sleep_for(std::chrono::milliseconds(5)); // Tightened to 5ms for faster response

#ifdef _WIN32
    // Forces the Windows scheduler to switch threads
    R_CheckUserInterrupt();
#endif
  }

  if (cl_init_thread.joinable()) {
    cl_init_thread.join();
  }

  return success;
}


//' OpenCL initialization routine
//'
//' called via onLoad mechanism.
//' @param kernelPath string, contains path to load OpenCL kernel from.
//' @export
// [[Rcpp::export(name = "SetKernelsPath", rng = FALSE)]]
void SetKernelsPath(String kernelPath) {
  std::string path = kernelPath.get_cstring();
  backend::setKernelsPath(path);
  if (!opencl_bridge_established) {
    //  Initial access: The device set up during onLoad.
    backend::sync_global_device();
    opencl_bridge_established = true;
  }
}

//' Check if OpenCL device is ready.
//'
//' @return logical, indicates state of device
//' @export
// [[Rcpp::export(name = "IsOpenCLReady", rng = FALSE)]]
bool IsOpenCLReady() {
  return backend::CLpp::instance().isInitialized();
}



//' Toggles detailed OpenCL diagnostics and hardware tables in the terminal
//' @param state bool, TRUE to turn on, FALSE to mute
//' @export
// [[Rcpp::export(name = "ToggleOpenCLPrint", rng = FALSE)]]
void ToggleOpenCLPrint(bool state) {
  // Writes the new value directly into the C++11 singleton via the reference!
  get_opencl_print_enabled() = state;
}


// [[Rcpp::export(name = ".GetActiveDeviceInfo_cpp", rng = FALSE)]]
List GetActiveDeviceInfo() {
  // CRASH PROTECTION:
  // We catch the nullptr BEFORE the storage controller complains!
  if (global_opencl_device == nullptr || !global_opencl_device->exists()) {
    Rcpp::stop("OpenCLeaR backend error: No OpenCL device is active! Please activate a device with 'ActivateDevice()' first.");
  }

  // We access the info structure of our global storage anchor directly!
  // Since this object is synchronized in RAM, it always holds
  // data from the exactly selected card (NVIDIA, Intel or CPU) in it.
  const auto& d = global_opencl_device->info;


#if defined(_WIN32)
  const std::string os = "Windows";
#elif defined(__linux__)
  const std::string os = "Linux";
#elif defined(__APPLE__)
  const std::string os = "macOS";
#else
  const std::string os = "unknown";
#endif

  return List::create(
                      _["Index"]         = d.id, ///<<<< FIXME!!!!
                      _["Platform_ID"]   = global_opencl_device->platform_id(),
                      _["Device_ID"]     = global_opencl_device->device_id(),
                      _["Device_Address"] = (double)(uintptr_t)global_opencl_device,
                      _["Name"]           = d.name,
                      _["Vendor"]         = d.vendor,
                      _["OS"]             = os,
                      _["Driver_Version"] = d.driver_version,
                      _["OpenCL_Version"] = "OpenCL C " + d.opencl_c_version,
                      _["Compute_Units"]  = d.compute_units,
                      _["Clock_MHz"]      = d.clock_frequency,
                      _["Cores"]          = d.cores,
                      _["TFLOPs"]         = d.tflops,
                      _["Memory_MB"]      = d.memory,
                      _["Uses_RAM"]       = d.uses_ram,
                      _["Global_Cache_KB"]= d.global_cache,
                      _["Local_Cache_KB"] = d.local_cache,
                      _["Max_Buffer_MB"]  = d.max_global_buffer,
                      _["Max_Constant_KB"]= d.max_constant_buffer,
                      _["FP64_Capable"]   = (d.is_fp64_capable >= 1)
                      );
}

// [[Rcpp::export(name = ".is_device_bound_cpp", rng = FALSE)]]
bool is_device_bound() {
  // Just returns TRUE or FALSE without ever touching hardware
  return (global_opencl_device != nullptr);
}

// [[Rcpp::export(name = ".GetDeviceList_cpp", rng = FALSE)]]
DataFrame GetDeviceList() {
  // 1. We call the original upstrem wrapper function
  std::vector<Device_Info> devices = get_devices(false);

  // Prepare Rcpp vectors for the DataFrame columns
  IntegerVector device_ids;
  IntegerVector hardware_platform_ids;
  IntegerVector hardware_device_ids; 
  CharacterVector device_names;
  CharacterVector device_vendors;
  NumericVector compute_units;
  NumericVector clock_mhz;
  NumericVector cores_count;
  NumericVector tflops_perf;
  NumericVector vram_mb;
  LogicalVector fp64_capable;

  // 2. We loop over the returned device vector
  for (size_t i = 0; i < devices.size(); ++i) {
    const auto& d = devices[i];

    device_ids.push_back(d.id);
    hardware_platform_ids.push_back(d.platform_idx);
    hardware_device_ids.push_back(d.device_idx); 
    device_names.push_back(d.name);
    device_vendors.push_back(d.vendor);
    compute_units.push_back(d.compute_units);
    clock_mhz.push_back(d.clock_frequency);
    cores_count.push_back(d.cores);
    tflops_perf.push_back(d.tflops);
    vram_mb.push_back(d.memory);
    fp64_capable.push_back(d.is_fp64_capable >= 1);
  }

  // 3. Merge into R DataFrame
  return DataFrame::create(
                           _["Index"]         = device_ids,
                           _["Platform_ID"]   = hardware_platform_ids,
                           _["Device_ID"]     = hardware_device_ids, 
                           _["Name"]          = device_names,
                           _["Vendor"]        = device_vendors,
                           _["Compute_Units"] = compute_units,
                           _["Clock_MHz"]     = clock_mhz,
                           _["Cores"]         = cores_count,
                           _["TFLOPs"]        = tflops_perf,
                           _["VRAM_MB"]       = vram_mb,
                           _["FP64_Capable"]  = fp64_capable,
                           _["stringsAsFactors"] = false
                           );
}
// Allows R to read the internal kernel path non-blockingly
// [[Rcpp::export(name = ".GetKernelsPath_cpp", rng = FALSE)]]
std::string GetKernelsPath() {
  // We get the path directly and without blocking from the central instance!
  return backend::getKernelsPathFromBackend();
}

//' Get kernel code as seen by OpenCL
//'
//' @export
// [[Rcpp::export(name = "GetKernelCode", rng = FALSE)]]
String GetKernelCode() {
  // 1. Get pointer to the active, awake device from the backend
  Device* device = const_cast<Device*>(&backend::getActiveDeviceFromBackend());

  // 2. Call the method directly via the object (since it is a member of Device!)
  std::string code = device->get_kernel_code();
  return wrap(code);
}
