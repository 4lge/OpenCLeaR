#pragma once

#ifndef CL_TARGET_OPENCL_VERSION
#define CL_TARGET_OPENCL_VERSION 300
#endif

// 1. Zuerst die OpenCL-C-Basis-Typen von Khronos laden
#include <CL/opencl.h>
#include <string>


// 2. Deine modifizierte Klasse 'Device' laden (wichtig für Device*)
#include "opencl.hpp"

struct TransientDevice {
  cl_context context;
  cl_device_id device;
  cl_command_queue queue;
  Device* wrapper_device;
  std::string kernel_path; // 🚀 Einheitlich ohne "s"
  bool fp64_capable;


  TransientDevice(int platform_id, int device_id, std::string k_path) {
    this->kernel_path = k_path;
    this->device = nullptr;
    this->context = nullptr;
    this->queue = nullptr;
    this->fp64_capable = false;

    // 1. Dynamisch die Anzahl der Plattformen ermitteln
    cl_uint num_platforms = 0;
    cl_int err = clGetPlatformIDs(0, NULL, &num_platforms);
    
    // Nur wenn gar keine Plattformen existieren, greift das CRAN-Null-Device stillschweigend
    if (err != CL_SUCCESS || num_platforms == 0) {
      this->wrapper_device = new Device(); 
      return;
    }

    std::vector<cl_platform_id> platforms(num_platforms);
    clGetPlatformIDs(num_platforms, platforms.data(), &num_platforms);

    // 🚀 EXCEPTION statt stillem Fallback bei ungültiger Plattform-ID
    if (platform_id >= (int)num_platforms) {
      Rcpp::stop("OpenCL Error: platform_id %d is out of range (total platforms: %d)", platform_id, num_platforms);
    }
    cl_platform_id platform = platforms[platform_id];

    // 2. Dynamisch die Anzahl der Geräte (erst GPU, dann Fallback) ermitteln
    cl_uint num_devices = 0;
    err = clGetDeviceIDs(platform, CL_DEVICE_TYPE_GPU, 0, NULL, &num_devices);
    
    std::vector<cl_device_id> devices;
    if (err == CL_SUCCESS && num_devices > 0) {
      devices.resize(num_devices);
      clGetDeviceIDs(platform, CL_DEVICE_TYPE_GPU, num_devices, devices.data(), &num_devices);
    } else {
      // Fallback auf ALL
      err = clGetDeviceIDs(platform, CL_DEVICE_TYPE_ALL, 0, NULL, &num_devices);
      if (err != CL_SUCCESS || num_devices == 0) {
        Rcpp::stop("OpenCL Error: No OpenCL devices found for platform %d", platform_id);
      }
      devices.resize(num_devices);
      clGetDeviceIDs(platform, CL_DEVICE_TYPE_ALL, num_devices, devices.data(), &num_devices);
    }

    // 🚀 EXCEPTION statt stillem Fallback bei ungültiger Device-ID
    if (device_id >= (int)num_devices) {
      Rcpp::stop("OpenCL Error: device_id %d is out of range (total devices on platform: %d)", device_id, num_devices);
    }

    // Valide Hardware-ID zuweisen
    this->device = devices[device_id];

    // 3. Extensions dynamisch auslesen
    size_t ext_size = 0;
    clGetDeviceInfo(this->device, CL_DEVICE_EXTENSIONS, 0, NULL, &ext_size);
    std::vector<char> ext_buffer(ext_size);
    clGetDeviceInfo(this->device, CL_DEVICE_EXTENSIONS, ext_size, ext_buffer.data(), NULL);
    std::string extensions(ext_buffer.data(), ext_size);

    this->fp64_capable = (extensions.find("cl_khr_fp64") != std::string::npos) ||
                         (extensions.find("cl_amd_fp64") != std::string::npos);

    // 4. Kontext und Queue erzeugen
    this->context = clCreateContext(NULL, 1, &this->device, NULL, NULL, &err);
    if (err != CL_SUCCESS) {
      Rcpp::stop("OpenCL Error: Failed to create context for device %d (error code %d)", device_id, err);
    }
    
#ifdef __APPLE__
    // 🍏 macOS nutzt den reinen OpenCL 1.2 Standard-Befehl
    this->queue = clCreateCommandQueue(this->context, this->device, 0, &err);
#else
    // 🚀 Windows/Linux nutzen die modernen 2.0+ Properties
    this->queue = clCreateCommandQueueWithProperties(this->context, this->device, 0, &err);
#endif
    if (err != CL_SUCCESS) {
      Rcpp::stop("OpenCL Error: Failed to create command queue for device %d (error code %d)", device_id, err);
    }

    // 5. Wrapper initialisieren
    this->wrapper_device = new Device(this->context, this->device, this->queue);
    this->wrapper_device->info.is_fp64_capable = this->fp64_capable;
    this->wrapper_device->set_kernel_path(k_path);
   // 🚀 DIE ABSOLUTE LEXBOOK-RETTUNG: Reicht die echten Indizes an den Wrapper weiter!
    // 🚀 DIE ABSOLUTE REINFELD-ELEGANZ: 
    // Wir nutzen deine echten, überladenen C++ Setter-Methoden der opencl.hpp!
    this->wrapper_device->platform_id(platform_id); // Involviert den legalen private-Schreibzugriff
    this->wrapper_device->device_id(device_id);     // Involviert den legalen private-Schreibzugriff
  }
  // Direkter Getter auf TransientDevice-Ebene
  std::string get_kernel_path() const {
    return this->kernel_path;
  }
  // 🚀 NEU: Setter-Methode, um den Pfad nachträglich zu aktualisieren
  void set_kernel_path(std::string k_path) {
    this->kernel_path = k_path;
  }
  ~TransientDevice() {
    delete wrapper_device;
    if (queue)   clReleaseCommandQueue(queue);
    if (context) clReleaseContext(context);
  }
};

