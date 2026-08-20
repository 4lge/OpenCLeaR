#pragma once

#include "OpenCL-Wrapper/opencl.hpp" 
#include <string>

namespace backend {

    class OpenCLeaRDevice : public Device {
    public:
        
        // 🚀 DIE SCHLAUE TÄUSCHUNG: Wir füttern den einzig existierenden Original-Konstruktor 
        // der Basisklasse mit einem fliegend instanziierten 'Device_Info'-Objekt!
        OpenCLeaRDevice(const cl::Context& ext_context, const cl::Device& ext_device, const cl::CommandQueue& ext_queue) 
            : Device(Device_Info(ext_device, ext_context, 0u), "") {
            
            // Da das originale Device standardmäßig seine eigene Queue erzeugt hätte,
            // biegen wir die interne cl_queue hier einfach auf deine stabile R-Session-Queue um:
            // (Wir nutzen die im originalen Wrapper enthaltene Methode, um die Queue zu setzen)
            this->set_queue(ext_queue);
            
            this->exists = true;
            this->kernel_compiled = false;
        }

        // Dummy-Konstruktor für den stummen Fallback
        OpenCLeaRDevice() : Device() {}
        
    private:
        // Kleine interne Hilfsmethode, um an das private cl_queue-Feld der Basisklasse 
        // heranzukommen, ohne den Code im Original-Submodul anfassen zu müssen:
        void set_queue(const cl::CommandQueue& target_queue) {
            // Der originale Wrapper bietet uns Zugriff auf das Info-Paket,
            // aber wir tricksen den C++ Linker über einen sauberen Cast aus, falls nötig.
            // Zum Glück ist 'info' im originalen Device PUBLIC deklariert!
            this->info.cl_queue = target_queue;
        }
    };

}

