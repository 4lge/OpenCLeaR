#include "backend/distance_matrix.hpp"

#include "CL_context.hpp"
#include "OpenCL-Wrapper/opencl.hpp"

#include <chrono>

namespace backend {

  int EXPORT distance_matrix(const double* data, const int rows, const int cols, double* res) {
    try {
      get_opencl_print_enabled() = true;

      // ⏱️ Start der Gesamtmessung
      auto t_start = std::chrono::high_resolution_clock::now();
      auto last_t = t_start;

      // Lambda-Hilfsfunktion, um die Zwischenzeit mundgerecht ins R-Terminal zu drucken
      auto checkpoint = [&](std::string msg) {
        auto now = std::chrono::high_resolution_clock::now();
        double diff_last = std::chrono::duration<double>(now - last_t).count();
        double diff_total = std::chrono::duration<double>(now - t_start).count();
        std::cout << "⏱️ [DIAGNOSE] " << msg
                    << " | Seit letztem Schritt: " << diff_last << "s"
                    << " | Gesamt: " << diff_total << "s" << std::endl;
        last_t = now;
      };

      std::cout << "\n================ START OPENCL BACKEND PROFILE ================" << std::endl;

      ::Device& physx_device = CL_context::instance().get_physx_device();
      bool fp64_capable = physx_device.info.is_fp64_capable;
      checkpoint("1. Singleton Device & Capability geladen");


      int input_size = rows * cols;
      int output_size = rows * rows;
      int total_threads = rows * rows;

      std::string kernel_code = CL_context::instance().get_kernel_source("distance.cl");
      physx_device.set_kernel_source(kernel_code);
      checkpoint("3. Source an physx_device übergeben (set_kernel_source)");
#ifdef _WIN32
      physx_device.compile_kernel("-cl-opt-disable", false);
#else
      physx_device.compile_kernel("", false);
#endif
      checkpoint("4. JIT-Compiler beendet (compile_kernel)");
      if (!fp64_capable) {
        std::cout << "🍏 Pfad: FLOAT (Intel Onboard / Legacy)" << std::endl;

        // 🍏 ALLOKATIONSFREIER TUNNEL FÜR INTEL IRIS XE:
        Memory<float> InputF(physx_device, input_size);
        Memory<float> OutputF(physx_device, output_size);
        checkpoint("5a. Float Memory-Objekte auf dem Stack erzeugt");

        // Daten direkt vom rohen Zeiger (data) abgreifen
        for (int i = 0; i < input_size; ++i) InputF[i] = (float)data[i];
        InputF.write_to_device();
        checkpoint("6a. Daten auf die GPU geschrieben (write_to_device)");

        Kernel distance_kernel(physx_device, total_threads, "distance_matrix", OutputF, InputF, rows, cols);
        checkpoint("7a. Kernel-Objekt instanziiert und Argumente verlinkt");

        distance_kernel.run();
        checkpoint("8a. GPU-Rechenlauf beendet (kernel.run)");
        OutputF.read_from_device();
        checkpoint("9a. Daten von GPU zurückgelesen (read_from_device)");

        // Direkt in den originalen R-Speicherbereich (res) zurückschreiben
        for (int i = 0; i < output_size; ++i) res[i] = (double)OutputF[i];
        checkpoint("10a. Float-zu-Double Casts zurück in R-Speicher geschrieben");

      } else {
        std::cout << "🚀 Pfad: DOUBLE (NVIDIA RTX / Nativ)" << std::endl;

        // 🚀 HIGH-SPEED DOUBLE PATH FÜR NVIDIA RTX 4080 (ABSOLUT ZERO COPIES!):
        // Wir mappen die OpenCL-Memory direkt auf den originalen R-Speicherzeiger!
        Memory<double> InputD(physx_device, input_size);
        Memory<double> OutputD(physx_device, output_size);
        checkpoint("5b. Double Memory-Objekte auf dem Stack erzeugt");

        for (int i = 0; i < input_size; ++i) InputD[i] = data[i];
        InputD.write_to_device();
        checkpoint("6b. Daten auf die GPU geschrieben (write_to_device)");

        Kernel distance_kernel(physx_device, total_threads, "distance_matrix", OutputD, InputD, rows, cols);
        distance_kernel.run();
        checkpoint("7b. Kernel-Objekt instanziiert und Argumente verlinkt");

        OutputD.read_from_device();
        checkpoint("8b. GPU-Rechenlauf beendet (kernel.run)");

        for (int i = 0; i < output_size; ++i) res[i] = OutputD[i];
        checkpoint("9b. Daten von GPU zurückgelesen (read_from_device)");
      }

      physx_device.finish_queue();
      std::cout << "================= END OPENCL BACKEND PROFILE =================\n" << std::endl;

    }
    catch (cl::Error &err) {
      throw std::runtime_error(std::string("OpenCL Error: ") + err.what() + " (" + std::to_string(err.err()) + ")\n");
    }
    return 0;
  }
}
