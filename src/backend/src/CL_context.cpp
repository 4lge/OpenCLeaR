#include "CL_context.hpp"

#include <fstream>
#include <sstream>
#include <string>
#include <vector>
#include <iostream>


namespace backend {

  CL_context::CL_context() {
    this->has_hardware = false; // Standardmäßig erst mal deaktiviert
    std::vector<cl::Platform> platforms;

    try {
      // 🚀 DIE CRAN-RETTUNG: Wir fangen den Khronos-C++ Rückgabecode direkt ab
      cl_int platform_err = cl::Platform::get(&platforms);

      // Wenn der Treiber-Loader meldet: Keine Plattformen da (-1001) oder Fehler
      if (platform_err == -1001 || platform_err != CL_SUCCESS || platforms.empty()) {
        std::cout << "*** IMPORTANT: No OpenCL platforms were found! Entering Fallback Mode. ***" << std::endl;
        return; // 🍏 Bricht geräuschlos ab! KEIN throw, das Paket lädt fehlerfrei!
      }
    } catch (const cl::Error &e) {
      // Falls das System statt eines Fehlercodes eine echte C++-Exception wirft (z.B. bei -1001)
      if (e.err() == -1001) {
        std::cout << "*** IMPORTANT: No OpenCL platforms were found (Exception -1001)! Entering   Fallback Mode. ***" << std::endl;
      } else {
        std::cout << "*** OpenCLeaR Initializer skipped due to OpenCL Error: " << e.what() << " (" << e.err() << ") ***" << std::endl;
      }
      return; // 🍏 Beendet den Konstruktor lautlos pro CRAN/Winbuilder!
    }

    bool found = false;

    for (const auto& platform : platforms) {
      std::vector<cl::Device> devices;

      // Auch den Device-Scan vor unvorhergesehenen Treiber-Abstürzen absichern
      try {
        if (platform.getDevices(CL_DEVICE_TYPE_ALL, &devices) != CL_SUCCESS || devices.empty()) {
          continue;
        }
      } catch (const cl::Error &) {
        continue; // Überspringe Plattformen ohne lauffähige Geräte
      }

      for (const auto& dev : devices) {
        cl_device_type type = dev.getInfo<CL_DEVICE_TYPE>();
        cl_uint compute_units = dev.getInfo<CL_DEVICE_MAX_COMPUTE_UNITS>();
        std::string name = dev.getInfo<CL_DEVICE_NAME>();
        std::string vendor = dev.getInfo<CL_DEVICE_VENDOR>();

        std::cout << "Found device: " << name << " (" << vendor << ")"
                  << " | Type: " << (type == CL_DEVICE_TYPE_GPU ? "GPU" :
                                     type == CL_DEVICE_TYPE_CPU ? "CPU" :
                                     type == CL_DEVICE_TYPE_ACCELERATOR ? "Accelerator" : "Other")
                  << " | Compute Units: " << compute_units << "\n";

        // Universeller Priorisierungs-Scan (GPU > CPU)
        if (!found || (type == CL_DEVICE_TYPE_GPU && best_device.getInfo<CL_DEVICE_TYPE>() != CL_DEVICE_TYPE_GPU) ||
            (type == best_device.getInfo<CL_DEVICE_TYPE>() && compute_units > best_device.getInfo<CL_DEVICE_MAX_COMPUTE_UNITS>())) {
          best_device = dev;
          best_platform = platform;
          found = true;
        }
      }
    }

    // Wenn physisch absolut kein passendes Gerät gefunden wurde
    if (!found) {
      std::cout << "*** IMPORTANT: No suitable OpenCL devices found. Entering Fallback Mode. ***" << std::endl;
      return; // 🍏 Geräuschloser Abbruch für treiberlose Systeme!
    }

    std::cout << "Selected device: " << best_device.getInfo<CL_DEVICE_NAME>()
              << " on platform: " << best_platform.getInfo<CL_PLATFORM_NAME>() << "\n";

    try {
      // Use best_device and best_platform to create context and queue:
      context = cl::Context(best_device);
      queue = cl::CommandQueue(context, best_device);
      this->has_hardware = true; // 🚀 ERFOLG: Hardware ist voll einsatzbereit!
    } catch (const cl::Error &e) {
      std::cout << "*** OpenCLeaR Context Generation Error: " << e.what() << ". Mode: Fallback. ***" << std::endl;
      this->has_hardware = false;
    }
    // ⚡ EINMALIGE HARDWARE-ZÜNDUNG BEIM LADEN DES PAKETS:
    // Erzeugt das langlebige Device-Objekt deines Forks direkt auf dem Heap des Singletons.
    this->global_physx_device = ::Device(this->get_context()(), this->get_device()(), this->get_queue()());
    
    // Holt die Extensions sicher über die offizielle get_device() Funktion
    std::string extensions = this->get_device().getInfo<CL_DEVICE_EXTENSIONS>();
    this->global_physx_device.info.is_fp64_capable = 
        (extensions.find("cl_khr_fp64") != std::string::npos) || 
        (extensions.find("cl_amd_fp64") != std::string::npos);

  }




  CL_context::~CL_context() {}

  CL_context& CL_context::instance() {
   // Wir erstellen die Instanz als persistenten Pointer auf dem Heap.
   // C++ versucht dadurch beim Beenden von R NICHT mehr, den Destruktor
   // aufzurufen, was den finalen Absturz beim Schließen restlos eliminiert!
    static CL_context* instance_ptr = new CL_context();
    return *instance_ptr;
  }



  Device& CL_context::get_physx_device() {
    // Liefert die langlebige Referenz an deine Rechenkerne aus
    return this->global_physx_device;
  }

  void CL_context::set_kernels_path(const std::string& path) {
    std::lock_guard<std::mutex> lock(mutex);
    kernels_path = path;
  }

  std::string CL_context::get_kernels_path() const {
    std::lock_guard<std::mutex> lock(mutex);
    return kernels_path;
  }

  const cl::Context& CL_context::get_context() const {
    return context;
  }

  const cl::CommandQueue& CL_context::get_queue() const {
    return queue;
  }

  const cl::Device& CL_context::get_device() const {
    return best_device;
  }

  std::string CL_context::get_kernel_source(const std::string& filename) const {
    std::ifstream file(kernels_path + "/" + filename);
    if (!file.is_open()) {
        throw std::runtime_error("OpenCLeaR Error: Kernel-Datei nicht gefunden: " + filename);
    }
    std::stringstream ss;
    ss << file.rdbuf();
    return ss.str();
  }

  cl::Program CL_context::get_program(const std::string& filename) const {
    std::ifstream file(kernels_path + "/" + filename);
    if (!file.is_open()) {
      throw std::runtime_error("Failed to open kernel file: " + filename);
    }
    std::stringstream ss;
    ss << file.rdbuf();
    std::string file_content = ss.str();

    // 🚀 START DES REAL_T HACKS: Extensions des gewählten Geräts live prüfen
    std::string extensions = best_device.getInfo<CL_DEVICE_EXTENSIONS>();
    bool fp64_capable = (extensions.find("cl_khr_fp64") != std::string::npos) ||
      (extensions.find("cl_amd_fp64") != std::string::npos);

    // Header-Präfix dynamisch im RAM zusammenbauen
    std::string kernel_prefix = "";
    if (fp64_capable) {
      kernel_prefix += "#pragma OPENCL EXTENSION cl_khr_fp64 : enable\n";
      kernel_prefix += "typedef double real_t;\n";
      kernel_prefix += "typedef double2 real2_t;\n"; // Hilfstypen bei Bedarf
    } else {
      kernel_prefix += "typedef float real_t;\n";
      kernel_prefix += "typedef float2 real2_t;\n";
    }

    // Präfix und Datei-Inhalt zu einem einzigen, vollständigen Kernel-String verschmelzen
    std::string kernel_str = kernel_prefix + file_content;

    // Ausgabe zur Kontrolle im R-Terminal (zeigt uns genau, was der Treiber kriegt!)
    std::cout << "--- Compiling Kernel Source ---" << std::endl;
    std::cout << kernel_str << std::endl;
    std::cout << "-------------------------------" << std::endl;

    cl::Program::Sources sources;
    sources.push_back({kernel_str.c_str(), kernel_str.length()});
    cl::Program program(context, sources);

    cl_int err = program.build("-cl-fast-relaxed-math");
    if (err != CL_SUCCESS) {
      std::string buildlog = program.getBuildInfo<CL_PROGRAM_BUILD_LOG>(best_device);
      throw std::runtime_error("Error building: " + buildlog + "\n");
    }

    return program;
  }

}
