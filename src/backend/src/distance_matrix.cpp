#include "backend/distance_matrix.hpp"

namespace backend {

    EXPORT int distance_matrix(const std::vector<double>& data, const int rows, const int cols, std::vector<double>& res) {
        try {
          get_opencl_print_enabled() = true;
            const cl::Context& context = CL_context::instance().get_context();
            const cl::CommandQueue& queue = CL_context::instance().get_queue();
            const cl::Device& raw_device = CL_context::instance().get_device();

            std::string extensions = raw_device.getInfo<CL_DEVICE_EXTENSIONS>();
            bool fp64_capable = (extensions.find("cl_khr_fp64") != std::string::npos) ||
                                (extensions.find("cl_amd_fp64") != std::string::npos);

            // 🚀 ZÜNDUNG DEINER TRANSIENTEN STACK-KLASSE:
            // Wir nutzen den perfekt sitzenden, überladenen Konstruktor deines Forks!
            Device physx_device(context(), raw_device(), queue());
            physx_device.info.is_fp64_capable = fp64_capable;
            physx_device.info.opencl_c_version = "3.0";
            //  physx_device.exists          = true;

            // Kernel-Quelltext über die neue Methode deines Singletons holen
            std::string kernel_code = CL_context::instance().get_kernel_source("distance.cl");

            // Über die RAM-Injektion deines Forks einspeisen und kompilieren
            physx_device.set_kernel_source(kernel_code);
            physx_device.compile_kernel("", true); // force_load auf true, um JIT zu erzwingen

            int input_size = rows * cols;
            int output_size = rows * rows;

            // 🚀 UPSTREAM-COMPATIBLE: Das flache 1D-Gesamtgitter bestimmen!
            int total_threads = rows * rows;

            Memory<double> InputD;
            Memory<float>  InputF;
            Memory<double> OutputD;
            Memory<float>  OutputF;

            Kernel distance_kernel;

            if (!fp64_capable) {
                // 🍏 TUNNEL FÜR INTEL IRIS XE (Float / 4 Byte)
                InputF  = Memory<float>(physx_device, input_size);
                OutputF = Memory<float>(physx_device, output_size);

                // Double-Eingangsdaten nach float konvertieren
                for (size_t i = 0; i < input_size; ++i) {
                    InputF[i] = (float)data[i];
                }
                InputF.write_to_device();

                // Kernel über deinen universellen Variadic-Template-Konstruktor instanziieren
                distance_kernel = Kernel(physx_device, total_threads, "distance_matrix", OutputF, InputF, rows, cols);
            } else {
                // 🚀 HIGH-SPEED PATH FÜR NVIDIA / LINUX-SERVER (Double / 8 Byte)
                InputD  = Memory<double>(physx_device, input_size);
                OutputD = Memory<double>(physx_device, output_size);

		for (size_t i = 0; i < input_size; ++i) {
                    InputD[i] = data[i];
                }
                InputD.write_to_device();

                distance_kernel = Kernel(physx_device, total_threads, "distance_matrix", OutputD, InputD, rows, cols);
            }

            // 🔥 FEUER FREI AUF DER GPU 🔥
            distance_kernel.run();

            // Ergebnisse bytesynchron vom Device abholen und zurück in den Zielvektor gießen
            if (!fp64_capable) {
                OutputF.read_from_device();
                for (size_t i = 0; i < OutputF.length(); i++) {
                    res[i] = (double)OutputF[i];
                }
            } else {
                OutputD.read_from_device();
                for (size_t i = 0; i < OutputD.length(); i++) {
                    res[i] = OutputD[i];
                }
            }
            // Befehlskette abschließen, bevor der C++ Stack-Frame aufgeräumt wird
            queue.finish();
        }
        catch (cl::Error &err) {
            throw std::runtime_error(std::string("OpenCL Error: ") + err.what() + " (" + std::to_string(err.err()) + ")\n");
        }
        return 0;
    }

}


