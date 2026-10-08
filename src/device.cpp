#include <Rcpp.h>
#include "device.hpp" // Enthält die Definition deines TransientDevice-Structs
#include "opencl.hpp" // Enthält deine modifizierte Device-Klasse

using namespace Rcpp;

// 🚀 DIE BRÜCKE: Erzeugt das Gerät im C++ RAM und gibt den Pointer an R
// [[Rcpp::export(name = ".create_transient_device_cpp")]]
SEXP create_transient_device_cpp(int platform_id, int device_id, std::string kernel_path) {
    // Ruft den Konstruktor deines Structs auf (der clCreateContext etc. ausführt)
    TransientDevice* t_dev = new TransientDevice(platform_id, device_id, kernel_path);
    // Verpackt den nackten C++ Zeiger in ein Rcpp XPtr-Objekt.
    // 'true' sorgt dafür, dass Rcpp den Destruktor ~TransientDevice() automatisch
    // aufruft, falls der Pointer in R jemals gelöscht oder überschrieben wird.
    // 🚀 BOMBENFEST: 'false' verbietet Rcpp das aggressive, automatische Zerstören des OpenCL-Kontexts!
    Rcpp::XPtr<TransientDevice> ptr(t_dev, false);
 
    return ptr;
}

// [[Rcpp::export(name = ".set_transient_device_path_cpp")]]
void set_transient_device_path_cpp(SEXP device_xptr, std::string kernel_path) {
    Rcpp::XPtr<TransientDevice> ptr(device_xptr);
    if (ptr) {
        ptr->set_kernel_path(kernel_path);
    }
}
