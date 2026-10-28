#include <Rcpp.h>

#include "device.hpp" // Enthält die Definition deines TransientDevice-Structs
#include "opencl.hpp" // Enthält deine modifizierte Device-Klasse
#include "backend/init.hpp" // 🚀 Macht global_opencl_device und Device sichtbar!

 
// Falls der Header nicht ausreicht, deklarieren wir es hier explizit als extern:
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
    // Ruft den Konstruktor deines Structs auf (der clCreateContext etc. ausführt)
  TransientDevice* t_dev = new TransientDevice(index, platform_id, device_id, kernel_path);

    // 🚀 DER GENIALE SOMMER-SYNC:
    // Wir weisen dem Backend das echte, intern erzeugte Wrapper-Geraet zu!
    global_opencl_device = t_dev->wrapper_device;
    
    // Verpackt den nackten C++ Zeiger in ein Rcpp XPtr-Objekt.
    // 'true' sorgt dafür, dass Rcpp den Destruktor ~TransientDevice() automatisch
    // aufruft, falls der Pointer in R jemals gelöscht oder überschrieben wird.
    // 🚀 BOMBENFEST: 'false' verbietet Rcpp das aggressive, automatische Zerstören des OpenCL-Kontexts!
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
