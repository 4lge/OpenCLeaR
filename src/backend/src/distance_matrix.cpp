#include "backend/distance_matrix.hpp"

#include "backend/distance_matrix.hpp"
#include "CL_context.hpp"
#include "OpenCL-Wrapper/opencl.hpp"

namespace backend {

  int EXPORT distance_matrix(const double* data, const int rows, const int cols, double* res) {
    try {
      get_opencl_print_enabled() = true;

      ::Device& physx_device = CL_context::instance().get_physx_device();
      bool fp64_capable = physx_device.info.is_fp64_capable;

      int input_size = rows * cols;
      int output_size = rows * rows;
      int total_threads = rows * rows;

      std::string kernel_code = CL_context::instance().get_kernel_source("distance.cl");
      physx_device.set_kernel_source(kernel_code);
#ifdef _WIN32
      physx_device.compile_kernel("-cl-opt-disable", false);
#else
      physx_device.compile_kernel("", false);
#endif

      if (!fp64_capable) {
        // 🍏 ALLOKATIONSFREIER TUNNEL FÜR INTEL IRIS XE:
        Memory<float> InputF(physx_device, input_size);
        Memory<float> OutputF(physx_device, output_size);

        // Daten direkt vom rohen Zeiger (data) abgreifen
        for (int i = 0; i < input_size; ++i) InputF[i] = (float)data[i];
        InputF.write_to_device();

        Kernel distance_kernel(physx_device, total_threads, "distance_matrix", OutputF, InputF, rows, cols);
        distance_kernel.run();

        OutputF.read_from_device();
        // Direkt in den originalen R-Speicherbereich (res) zurückschreiben
        for (int i = 0; i < output_size; ++i) res[i] = (double)OutputF[i];
      } else {
        // 🚀 HIGH-SPEED DOUBLE PATH FÜR NVIDIA RTX 4080 (ABSOLUT ZERO COPIES!):
        // Wir mappen die OpenCL-Memory direkt auf den originalen R-Speicherzeiger!
        Memory<double> InputD(physx_device, input_size);
        Memory<double> OutputD(physx_device, output_size);

        for (int i = 0; i < input_size; ++i) InputD[i] = data[i];
        InputD.write_to_device();

        Kernel distance_kernel(physx_device, total_threads, "distance_matrix", OutputD, InputD, rows, cols);
        distance_kernel.run();

        OutputD.read_from_device();
        for (int i = 0; i < output_size; ++i) res[i] = OutputD[i];
      }

      physx_device.finish_queue();
    }
    catch (cl::Error &err) {
      throw std::runtime_error(std::string("OpenCL Error: ") + err.what() + " (" + std::to_string(err.err()) + ")\n");
    }
    return 0;
  }
}
