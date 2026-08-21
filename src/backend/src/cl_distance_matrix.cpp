#include "backend/distance_matrix.hpp"

#include "CL_context.hpp"
#include <iostream>
#include <vector>
#include <algorithm>

namespace backend {

    extern "C" void distance_matrix(double* data, int rows, int cols, double* res) {
        try {
            const cl::Context& context = CL_context::instance().get_context();
            const cl::CommandQueue& queue = CL_context::instance().get_queue();
            
            // 🚀 JETZT NEU: Das selektierte Gerät über das Singleton abfragen!
            // (Sollte deine Funktion anders heissen, z.B. .get_best_device(), kurz anpassen)
            const cl::Device& device = CL_context::instance().get_device();

            cl::Program program = CL_context::instance().get_program("distance.cl");
            cl::Kernel kernel(program, "distance_matrix");

            // FP64 Fähigkeit ermitteln
            std::string extensions = device.getInfo<CL_DEVICE_EXTENSIONS>();
            bool fp64_capable = (extensions.find("cl_khr_fp64") != std::string::npos) || 
                                (extensions.find("cl_amd_fp64") != std::string::npos);

            cl::NDRange global(rows, rows);

            if (!fp64_capable) {
                // 🍏 TUNNEL FÜR INTEL IRIS XE (Float / 4 Byte)
                int input_size = rows * cols;
                int output_size = rows * rows;

                // Double-Eingangsdaten nach float konvertieren
                std::vector<float> input_float(input_size);
                std::copy(data, data + input_size, input_float.begin());
                std::vector<float> output_float(output_size, 0.0f);

                // Puffer mit sizeof(float) aufbauen
                cl::Buffer inputBuffer(context, CL_MEM_READ_ONLY | CL_MEM_COPY_HOST_PTR, sizeof(float) * input_size, input_float.data());
                cl::Buffer outputBuffer(context, CL_MEM_WRITE_ONLY, sizeof(float) * output_size);

                kernel.setArg(0, outputBuffer);
                kernel.setArg(1, inputBuffer);
                kernel.setArg(2, rows);
                kernel.setArg(3, cols);

                queue.enqueueNDRangeKernel(kernel, cl::NullRange, global, cl::NullRange);
                queue.finish();

                // 4-Byte-Werte bytesynchron von der GPU laden
                queue.enqueueReadBuffer(outputBuffer, CL_TRUE, 0, sizeof(float) * output_size, output_float.data());

                // Ergebnisse zurück in den originalen R-Double-Zeiger (res) gießen
                std::copy(output_float.begin(), output_float.end(), res);

            } else {
                // 🚀 ORIGINAL-PFAD FÜR NVIDIA / LINUX (Double / 8 Byte)
                cl::Buffer inputBuffer(context, CL_MEM_READ_ONLY | CL_MEM_COPY_HOST_PTR, sizeof(double) * rows * cols, data);
                cl::Buffer outputBuffer(context, CL_MEM_WRITE_ONLY, sizeof(double) * rows * rows);

                kernel.setArg(0, outputBuffer);
                kernel.setArg(1, inputBuffer);
                kernel.setArg(2, rows);
                kernel.setArg(3, cols);

                queue.enqueueNDRangeKernel(kernel, cl::NullRange, global, cl::NullRange);
                queue.finish();

                queue.enqueueReadBuffer(outputBuffer, CL_TRUE, 0, sizeof(double) * rows * rows, res);
            }
        }
        catch (cl::Error &err) {
            throw std::runtime_error(std::string("OpenCL Error: ") + err.what() + " (" + std::to_string(err.err()) + ")\n");
        }
    }

}
