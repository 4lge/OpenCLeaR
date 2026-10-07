#include "CLpp.hpp"

#include <fstream>
#include <sstream>
#include <string>
#include <vector>
#include <iostream>



namespace backend {
  // Globale Variable zur Entkopplung des Pfads beim Paketstart
  // 🚀 WINDOWS-LOCK-BRECHER: Der Anker liegt außerhalb der Funktion auf Dateiebene!
  static CLpp* global_instance_anchor = nullptr;

  // 🚀 DIE RETTUNG FÜR DEN PFAD: Dem Compiler die Variable aus der init.cpp zeigen!
  std::string global_temporary_kernels_path;

  CLpp::CLpp() {
    // Standardkonstruktor bleibt für den Erfolgsfall leer,
    // da setupDevices() die Arbeit übernimmt.
  }

  CLpp::CLpp(bool dummy_mode) {
    // Macht absolut gar nichts. Verhindert jeden OpenCL-Aufruf.
    this->is_initialized = false;
  }

// 🎯 DIE GLOBALE SPEICHER-VARIABLE FÜR DIE LIBRARAY
static std::string global_math_library_code = "\n";

// 🎯 HIER WIRD DIE DATEI DYNAMISCH AUSGEGEBEN
inline std::string get_opencl_c_code() { 
    return global_math_library_code; 
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
  bool CLpp::setupDevices() {
    // 🚀 ZURÜCK ZUM FEHLERFREIEN URZUSTAND:
    // Wir lassen die Pfad-Zuweisung genau so, wie sie in deiner alten, funktionierenden 0.5.1 stand!
    // Wenn dort gearbeitet wurde mit:
    // this->kernels_path = "./kernels"; (oder ähnlich), behalte das bitgenau bei!

    this->is_initialized = false;

    std::cout << std::flush;

    return true;
  }
  Target_Device_Location CLpp::find_device_by_global_index(int target_global_index) {
    Target_Device_Location loc;
    loc.found = false;
    int current_global_index = 0;

    try {
      std::vector<cl::Platform> platforms;
      cl_int plat_err = cl::Platform::get(&platforms);
      if (plat_err != CL_SUCCESS || platforms.empty()) return loc;

      for (size_t p = 0; p < platforms.size(); ++p) {
        std::vector<cl::Device> devices;
        try {
          cl_int dev_err = platforms[p].getDevices(CL_DEVICE_TYPE_ALL, &devices);
          if (dev_err != CL_SUCCESS || devices.empty()) continue;
        } catch (...) { continue; } // Springt weich über defekte Plattformen

        for (size_t d = 0; d < devices.size(); ++d) {
          try {
            // Wir prüfen live, ob das Gerät antwortet
            std::string test_name = devices[d].getInfo<CL_DEVICE_NAME>();
            if (test_name.empty()) continue;

            // 🎯 VOLLETTREFFER: Der flache Index matcht!
            if (current_global_index == target_global_index) {
              loc.platform_idx = (int)p;
              loc.device_idx = (int)d;
              loc.found = true;
              return loc;
            }
            current_global_index++;
          }
          catch (...) { continue; } // Ignoriere defekte Einzelgeräte weich
        }
      }
    } catch (...) {}
    return loc;
  }


  void CLpp::activateDeviceWithIndex(int idx){
    // Kanäle vor dem Treiberlauf radikal freiputzen!
    std::cout << std::flush; std::cerr << std::flush;
    fflush(stdout); fflush(stderr);

    // 🚀 DER NVIDIA-CONTMEXT-RETTER (Verhindert das Umschalt-Sterben auf Linux):
    // Falls bereits ein Gerät aktiv war, reissen wir die Handles hier geordnet ab!
    if (this->is_initialized) {
        std::cerr << "  ⚠️ [CLpp.cpp] Schließe aktiven Kontext für Gerät sauber vor Wechsel..." << std::endl << std::flush;
        
        // Wir demaskieren das alte Gerät und entladen es im RAM manuell vor dem Move
        this->activeDevice = Device(); 
        
        std::cout << std::flush; std::cerr << std::flush;
        fflush(stdout); fflush(stderr);
    }

    std::cerr << "  ⏱️ [CLpp.cpp] 1. Initialisiere Hardware-Kontext frisch für Gerät Index " << idx << "..." << std::endl << std::flush;

    

    // select_device_with_id wird unzerstörbar mit dem aufgelösten Device-Index gefüttert!
    auto dev_info = select_device_with_id(idx);


    // 🚀 SCHRITT B: Die plattformspezifische Queue-Weiche (Brennt den Windows-Intel-Hänger weg!)
#ifdef _WIN32
    // Windows (Intel CPU) benötigt für den späteren JIT-Lauf eine leichte Runtime-Queue
    cl::Context temp_context(dev_info.cl_context(), true);
    cl::Device temp_device(dev_info.cl_device(), true);
    cl_int err = 0;
    cl::CommandQueue runtime_queue(temp_context, temp_device, 0, &err);
    cl_command_queue queue_handle = runtime_queue();
#else
    // Linux (NVIDIA) bleibt bei NULL für absolute Stabilität gegen Zähler-Segfaults!
    cl_command_queue queue_handle = NULL;
#endif

    // 🚀 SCHRITT C: Zünde den leichten, unblockierbaren Handle-Konstruktor!
    // Er lädt KEINEN mathematischen Quellcode und bricht das Windows-Warten augenblicklich!
    // 🚀 DYNAMISCH UND RECHTSSICHER: Holt die echten Indizes aus dev_info!
    Device nextDevice(
                      dev_info.cl_context(),
                      dev_info.cl_device(),
                      queue_handle,
                      dev_info.platform_idx,   // 🎯 Nimmt die echte Plattform-ID des Treibers!
                      dev_info.device_idx     // 🎯 Nimmt die echte Device-ID des Treibers!
                      );

    // Treibersicher via std::move an das langlebige Member übergeben
    this->activeDevice = std::move(nextDevice);
    this->is_initialized = true;
    //////
        // =========================================================================
    // 🚀 DER LIVE-METADATEN-REFRESH (Demaskiert NVIDIA / Intel Xeon augenblicklich!):
    // =========================================================================
    try {
        // Wir holen uns die Referenz auf das eben scharfgeschaltete Khronos-Gerät
        cl::Device& dev = this->activeDevice.info.cl_device;
        
        // Live die echten Strings direkt vom Herstellertreiber absaugen
        this->activeDevice.info.name = dev.getInfo<CL_DEVICE_NAME>();
        this->activeDevice.info.vendor = dev.getInfo<CL_DEVICE_VENDOR>();
        this->activeDevice.info.driver_version = dev.getInfo<CL_DRIVER_VERSION>();
        
        // Physikalische Hardware-Konfiguration auslesen
        this->activeDevice.info.compute_units = (uint)dev.getInfo<CL_DEVICE_MAX_COMPUTE_UNITS>();
        this->activeDevice.info.clock_frequency = (uint)dev.getInfo<CL_DEVICE_MAX_CLOCK_FREQUENCY>();
        this->activeDevice.info.memory = (uint)(dev.getInfo<CL_DEVICE_GLOBAL_MEM_SIZE>() / 1024u / 1024u);
        this->activeDevice.info.global_cache = (uint)(dev.getInfo<CL_DEVICE_GLOBAL_MEM_CACHE_SIZE>() / 1024u);
        this->activeDevice.info.local_cache = (uint)(dev.getInfo<CL_DEVICE_LOCAL_MEM_SIZE>() / 1024u);
        
        // FP64-Fähigkeit über die Extensions ermitteln
        std::string ext = dev.getInfo<CL_DEVICE_EXTENSIONS>();
        std::cout << "extensions: " << ext << std::endl;
        this->activeDevice.info.is_fp64_capable = (ext.find("cl_khr_fp64") != std::string::npos || ext.find("cl_amd_fp64") != std::string::npos);
        std::cout << "fp64: " << (this->activeDevice.info.is_fp64_capable? 1 : 0) << std::endl;
        // Dynamische Kerne- & TFLOPs-Berechnung (NVIDIA A2 vs. Xeon-CPU)
        const int vendor_id = (int)dev.getInfo<CL_DEVICE_VENDOR_ID>();
        const bool is_gpu = dev.getInfo<CL_DEVICE_TYPE>() == CL_DEVICE_TYPE_GPU;
        uint ipc = is_gpu ? 2u : 32u;
        float cores_per_cu = 1.0f;
        
        if (is_gpu && (vendor_id == 0x10DE || vendor_id == 0x1027F0)) { // NVIDIA
            std::string name_lower = this->activeDevice.info.name; 
            for(auto &c: name_lower) c = tolower(c);
            if(name_lower.find("rtx 40") != std::string::npos || name_lower.find("rtx 30") != std::string::npos || name_lower.find("a2") != std::string::npos) {
                cores_per_cu = 128.0f;
            } else if(name_lower.find("rtx 20") != std::string::npos || name_lower.find("titan") != std::string::npos) {
                cores_per_cu = 64.0f;
            } else {
                cores_per_cu = 32.0f;
            }
        }
        this->activeDevice.info.cores = (uint)((float)this->activeDevice.info.compute_units * cores_per_cu);
        this->activeDevice.info.tflops = ((float)this->activeDevice.info.cores * (float)this->activeDevice.info.clock_frequency * (float)ipc) / 1000000.0f;
        
    } catch (...) {
        // Falls ein Treiber beim Info-Scan zickt, setzen wir einen sauberen Fallback-Namen
        if (this->activeDevice.info.name.empty()) {
            this->activeDevice.info.name = "OpenCLeaR Active Hardware";
        }
    }
    //////
        // =========================================================================
    // 🚀 DER UNZICKIGE C-API LIVE SCAN (Brennt jeden try-Abbruch restlos weg!):
    // =========================================================================
    // size_t scan_size = 0;
    // clGetDeviceInfo(this->activeDevice.get_device_id(), CL_DEVICE_EXTENSIONS, 0, NULL, &scan_size);
    // std::vector<char> scan_buffer(scan_size);
    // clGetDeviceInfo(this->activeDevice.get_device_id(), CL_DEVICE_EXTENSIONS, scan_size, scan_buffer.data(), NULL);
    // std::string live_ext(scan_buffer.data(), scan_size);

    // // Wir zwingen das Feld unzerstörbar auf den echten Hardware-Zustand!
    // this->activeDevice.info.is_fp64_capable = (live_ext.find("cl_khr_fp64") != std::string::npos || 
    //                                            live_ext.find("cl_amd_fp64") != std::string::npos);

    // // Synchronisiert zeitgleich deinen neuen Index direkt im Core-Gerät!
    // this->activeDevice.info.index = idx;
    
    // Kanäle nach dem Laden entleeren
    std::cerr << "  🎉 [CLpp.cpp] SUCCESS: Gerät " << this->activeDevice.info.name << " erfolgreich scharfgeschaltet!\n" << std::endl << std::flush;
    std::cout << std::flush; std::cerr << std::flush;
    fflush(stdout); fflush(stderr);
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

  // 🚀 DIE RETTUNG FÜR DIE LIBBACKEND.SO:
  // Holt den Setter mitsamt der Thread-Sperre zurück in den physischen Quellcode!
  void CLpp::setKernelsPath(const std::string& str) {
    std::lock_guard<std::mutex> lock(mutex);
    this->kernels_path = str;
  }

  // Holt den Getter mitsamt der Thread-Sperre zurück in den physischen Quellcode!
  std::string CLpp::getKernelsPath() const {
    std::lock_guard<std::mutex> lock(mutex);
    return this->kernels_path;
  }


  CLpp& CLpp::instance() {
    if (global_instance_anchor == nullptr) {
      global_instance_anchor = new CLpp();
      global_instance_anchor->setupDevices();
    }
    return *global_instance_anchor;
  }


  CLpp::~CLpp() {}
}
