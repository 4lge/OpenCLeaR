#include <Rcpp.h>
#include "device.hpp" // Contains the definition of your TransientDevice struct
#include "opencl.hpp" // Includes the modified Device class
#include "backend/init.hpp" //  Makes global_opencl_device and device visible!

 
// If the header is not enough, we explicitly declare it as external here:
extern "C" Device* global_opencl_device;

using namespace Rcpp;


//' Creates an OpenCL device in C++ realm and gives the pointer to R
//' 
//' @param index global index of the device 
//' @param platform_id platform id of the device 
//' @param device_id device id within the platform of the device
//' @param kernel_path path to kernel store
// [[Rcpp::export(name = ".create_transient_device_cpp")]]
SEXP create_transient_device_cpp(int index, int platform_id, int device_id, std::string kernel_path) {
  // Calls the Device constructor (which runs clCreateContext etc.)
  TransientDevice* t_dev = new TransientDevice(index, platform_id, device_id, kernel_path);

    // We assign the real, internally generated wrapper device to the backend!
    global_opencl_device = t_dev->wrapper_device;
    
    // Wraps the bare C++ pointer into an Rcpp XPtr object.
    // 'false' prohibits Rcpp from aggressively destroying the
    // OpenCL context by calling  ~TransientDevice() destructor automatically!
    Rcpp::XPtr<TransientDevice> ptr(t_dev, false);
 
    return ptr;
}

//' pass a kernel path to the transient device
//'
//' @param device_xptr Rcpp Xptr of the C++ device
//' @param kernel_path path to kernel store to save in the transient device
// [[Rcpp::export(name = ".set_transient_device_path_cpp")]]
void set_transient_device_path_cpp(SEXP device_xptr, std::string kernel_path) {
    Rcpp::XPtr<TransientDevice> ptr(device_xptr);
    if (ptr) {
        ptr->set_kernel_path(kernel_path);
    }
}
