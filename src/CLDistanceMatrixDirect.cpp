#include <vector>
#include <algorithm>
#include <iostream>
#include <chrono>
#include <string>

// 🚀 HEADERS DEINES FORKS DIREKT EINBINDEN
#define CL_HPP_ENABLE_EXCEPTIONS
#define CL_TARGET_OPENCL_VERSION 300
#define CL_HPP_TARGET_OPENCL_VERSION 300
#define CL_HPP_MINIMUM_OPENCL_VERSION 100
#include <CL/opencl.hpp>
#include "OpenCL-Wrapper/opencl.hpp" 
#include "CL_context.hpp" // Holt dein stabiles Singleton!

#include <Rcpp.h>

using namespace Rcpp;

// [[Rcpp::export]]
NumericMatrix CLDistanceMatrixDirect(const NumericMatrix& mat) {
    
    int rows = mat.nrow();
    int cols = mat.ncol();
    NumericMatrix outmat(rows, rows);

    try {
        auto t_start = std::chrono::high_resolution_clock::now();
        auto last_t = t_start;

        auto checkpoint = [&](std::string msg) {
            auto now = std::chrono::high_resolution_clock::now();
            double diff_last = std::chrono::duration<double>(now - last_t).count();
            double diff_total = std::chrono::duration<double>(now - t_start).count();
            std::cout << "⏱️ [DIRECT-PROFILE] " << msg 
                      << " | Schritt: " << diff_last << "s"
                      << " | Gesamt: " << diff_total << "s" << std::endl << std::flush;
            last_t = now;
            Rcpp::checkUserInterrupt(); 
        };

        std::cout << "\n================ START DIRECT DLL INTERFACE PROFILE ================" << std::endl << std::flush;

        // 📍 MESSFELD 1 & 2: Wir leihen uns die bombenfesten Handles deines Singletons!
        // Das verhindert jegliche doppelten Destruktor-Aufrufe und eliminiert den Segfault restlos!
        cl::Context context      = backend::CL_context::instance().get_context();
        cl::CommandQueue queue   = backend::CL_context::instance().get_queue();
        cl::Device raw_device    = backend::CL_context::instance().get_device();
        checkpoint("1. Stabile Handles aus CL_context-Singleton geladen");

        // Wir instanziieren das Device deines Forks flüchtig mit den langlebigen Handles
        ::Device physx_device(context(), raw_device(), queue());
        
        std::string extensions = raw_device.getInfo<CL_DEVICE_EXTENSIONS>();
        bool fp64_capable = (extensions.find("cl_khr_fp64") != std::string::npos);
        physx_device.info.is_fp64_capable = fp64_capable;
        checkpoint("2. Wrapper Device-Objekt auf Singleton-Basis initialisiert");

        // 📍 MESSFELD 3: Kernel Quelltext-Zuweisung im RAM
        std::string kernel_code = R"(
            __kernel void distance_matrix(__global real_t* output, __global const real_t* input, const int N, const int DIM) {
                size_t flat_id = get_global_id(0);
                size_t i = flat_id % N;
                size_t j = flat_id / N;
                if (i < N && j < N) {
                    if (i == j) { output[j * N + i] = 0.0; return; }
                    if (j < i) {
                        real_t tmpRes = 0.0;
                        for (int k = 0; k < DIM; ++k) {
                            real_t diff = input[i + k * N] - input[j + k * N];
                            tmpRes += diff * diff;
                        }
                        tmpRes = sqrt(tmpRes);
                        output[j * N + i] = tmpRes;
                        output[i * N + j] = tmpRes;
                    }
                }
            }
        )";

        // =========================================================================
        // 📍 MESSFELD 3 & 4: DER ABSOLUTE COMPILE-BYPASS FÜR WINDOWS
        // =========================================================================
#ifdef _WIN32
        // 🚀 Unter Windows nutzen wir deine fehlerfreie get_program()-Methode!
        // Sie liest distance.cl direkt ein und baut das Program ungedrosselt über die rohe API,
        // wodurch der Intel-WDDM-JIT-Lock vollständig übersprungen wird!
        cl::Program program = backend::CL_context::instance().get_program("distance.cl");
        cl::Kernel raw_kernel(program, "distance_matrix");
        checkpoint("3 & 4. JIT-Compiler via get_program() hängerfrei beendet");
#else
        // Linux und Mac nutzen weiterhin Lehmanns eleganten String-Weg im RAM
        physx_device.set_kernel_source(kernel_code);
        checkpoint("3. Kernel-String an physx_device übergeben");

        physx_device.compile_kernel("", false);
        checkpoint("4. JIT-Compiler über Wrapper beendet (compile_kernel)");
#endif

        int input_size = rows * cols;
        int output_size = rows * rows;
        int total_threads = rows * rows;

        if (!fp64_capable) {
            std::cout << "🍏 Pfad: FLOAT (Intel Onboard / Legacy)" << std::endl << std::flush;

            Memory<float> InputF(physx_device, input_size);
            Memory<float> OutputF(physx_device, output_size);
            checkpoint("5a. Float Memory-Objekte auf dem Stack erzeugt");

            for (int i = 0; i < input_size; ++i) InputF[i] = (float)mat[i];
            InputF.write_to_device();
            checkpoint("6a. Daten auf die GPU geschrieben (write_to_device)");

#ifdef _WIN32
            // 🚀 Rohe Khronos-Argumentverlinkung für Windows, um den Lock zu umgehen:
            raw_kernel.setArg(0, OutputF.get_cl_buffer());
            raw_kernel.setArg(1, InputF.get_cl_buffer());
            raw_kernel.setArg(2, (cl_int)rows);
            raw_kernel.setArg(3, (cl_int)cols);
            checkpoint("7a. Rohe API-Argumente verlinkt");

            cl::NDRange global_range(rows, rows);
            queue.enqueueNDRangeKernel(raw_kernel, cl::NullRange, global_range, cl::NullRange);
            checkpoint("8a. GPU-Rechenlauf via rohe API beendet");
#else
            Kernel distance_kernel(physx_device, total_threads, "distance_matrix", OutputF, InputF, rows, cols);
            checkpoint("7a. Kernel-Objekt instanziiert und Argumente verlinkt");

            distance_kernel.run();
            checkpoint("8a. GPU-Rechenlauf beendet (kernel.run)");
#endif

            OutputF.read_from_device();
            for (int i = 0; i < output_size; ++i) outmat[i] = (double)OutputF[i];
            checkpoint("9a. Daten von GPU zurückgelesen und zurückkonvertiert");

        } else {
            std::cout << "🚀 Pfad: DOUBLE (NVIDIA RTX / Nativ)" << std::endl << std::flush;

            Memory<double> InputD(physx_device, input_size);
            Memory<double> OutputD(physx_device, output_size);
            checkpoint("5b. Double Memory-Objekte auf dem Stack erzeugt");

            std::copy(mat.begin(), mat.begin() + input_size, InputD.data());
            InputD.write_to_device();
            checkpoint("6b. Daten auf die GPU geschrieben (write_to_device)");

#ifdef _WIN32
            raw_kernel.setArg(0, OutputD.get_cl_buffer());
            raw_kernel.setArg(1, InputD.get_cl_buffer());
            raw_kernel.setArg(2, (cl_int)rows);
            raw_kernel.setArg(3, (cl_int)cols);
            
            cl::NDRange global_range(rows, rows);
            queue.enqueueNDRangeKernel(raw_kernel, cl::NullRange, global_range, cl::NullRange);
#else
            Kernel distance_kernel(physx_device, total_threads, "distance_matrix", OutputD, InputD, rows, cols);
            checkpoint("7b. Kernel-Objekt instanziiert und Argumente verlinkt");

            distance_kernel.run();
            checkpoint("8b. GPU-Rechenlauf beendet (kernel.run)");
#endif

            OutputD.read_from_device();
            std::copy(OutputD.data(), OutputD.data() + output_size, outmat.begin());
            checkpoint("9b. Daten bytesynchron in R-Speicher kopiert");
        }

        physx_device.finish_queue();
        checkpoint("10. Hardware-Queue final geleert (finish_queue)");

        std::cout << "================= END DIRECT DLL INTERFACE PROFILE =================\n" << std::endl << std::flush;
    }
    catch (cl::Error &err) {
        Rf_error("OpenCL Native Error: %s (%d)", err.what(), err.err());
    }

    return outmat;
}

