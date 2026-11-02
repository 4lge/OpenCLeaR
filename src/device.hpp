#pragma once

#ifndef CL_TARGET_OPENCL_VERSION
#define CL_TARGET_OPENCL_VERSION 300
#endif

// 1. First load the OpenCL-C base types from Khronos
#include <CL/opencl.h>
#include <string>


// 2. Load our modified OpenPhysx class 'Device' (important for device*)
#include "opencl.hpp"

struct TransientDevice {
  cl_context context;
  cl_device_id device;
  cl_command_queue queue;
  Device* wrapper_device;
  std::string kernel_path;
  bool fp64_capable;


  TransientDevice(int index, int platform_id, int device_id, std::string k_path) {
    this->kernel_path = k_path;
    this->device = nullptr;
    this->context = nullptr;
    this->queue = nullptr;
    this->fp64_capable = false;

    // 1. Dynamically determine the number of platforms
    cl_uint num_platforms = 0;
    cl_int err = clGetPlatformIDs(0, NULL, &num_platforms);
    
    // Only if no platforms exist the "zero" device takes effect silently
    if (err != CL_SUCCESS || num_platforms == 0) {
      this->wrapper_device = new Device(); 
      return;
    }

    std::vector<cl_platform_id> platforms(num_platforms);
    clGetPlatformIDs(num_platforms, platforms.data(), &num_platforms);

    // fallback if platform ID is invalid
    if (platform_id >= (int)num_platforms) {
      Rcpp::stop("OpenCL Error: platform_id %d is out of range (total platforms: %d)", platform_id, num_platforms);
    }
    cl_platform_id platform = platforms[platform_id];

    // 2. Dynamically determine the number of devices (first GPU, then fallback).
    cl_uint num_devices = 0;
    err = clGetDeviceIDs(platform, CL_DEVICE_TYPE_GPU, 0, NULL, &num_devices);
    
    std::vector<cl_device_id> devices;
    if (err == CL_SUCCESS && num_devices > 0) {
      devices.resize(num_devices);
      clGetDeviceIDs(platform, CL_DEVICE_TYPE_GPU, num_devices, devices.data(), &num_devices);
    } else {
      // Fallback to ALL
      err = clGetDeviceIDs(platform, CL_DEVICE_TYPE_ALL, 0, NULL, &num_devices);
      if (err != CL_SUCCESS || num_devices == 0) {
        Rcpp::stop("OpenCL Error: No OpenCL devices found for platform %d", platform_id);
      }
      devices.resize(num_devices);
      clGetDeviceIDs(platform, CL_DEVICE_TYPE_ALL, num_devices, devices.data(), &num_devices);
    }

    if (device_id >= (int)num_devices) {
      Rcpp::stop("OpenCL Error: device_id %d is out of range (total devices on platform: %d)", device_id, num_devices);
    }

    this->device = devices[device_id];

    // 3. Read extensions dynamically
    size_t ext_size = 0;
    clGetDeviceInfo(this->device, CL_DEVICE_EXTENSIONS, 0, NULL, &ext_size);
    std::vector<char> ext_buffer(ext_size);
    clGetDeviceInfo(this->device, CL_DEVICE_EXTENSIONS, ext_size, ext_buffer.data(), NULL);
    std::string extensions(ext_buffer.data(), ext_size);

    this->fp64_capable = (extensions.find("cl_khr_fp64") != std::string::npos) ||
                         (extensions.find("cl_amd_fp64") != std::string::npos);

    // 4. Create context and queue
    this->context = clCreateContext(NULL, 1, &this->device, NULL, NULL, &err);
    if (err != CL_SUCCESS) {
      Rcpp::stop("OpenCL Error: Failed to create context for device %d (error code %d)", device_id, err);
    }
    
#ifdef __APPLE__
    //  macOS uses the pure OpenCL 1.2 standard command
    this->queue = clCreateCommandQueue(this->context, this->device, 0, &err);
#else
    //  Windows/Linux use the modern 2.0+ properties
    this->queue = clCreateCommandQueueWithProperties(this->context, this->device, 0, &err);
#endif
    if (err != CL_SUCCESS) {
      Rcpp::stop("OpenCL Error: Failed to create command queue for device %d (error code %d)", device_id, err);
    }

    // 5. Initialize wrapper
    this->wrapper_device = new Device(
        this->context, 
        this->device, 
        this->queue, 
        index,   
        platform_id,
        device_id   
    );
    
    // Assign the metadata and paths
    this->wrapper_device->info.is_fp64_capable = this->fp64_capable;
    this->wrapper_device->set_kernel_path(k_path);
  }

  // Direct getter at TransientDevice level
  std::string get_kernel_path() const {
    return this->kernel_path;
  }

  // Setter method to update the path afterwards
  void set_kernel_path(std::string k_path) {
    this->kernel_path = k_path;
  }
  ~TransientDevice() {
    delete wrapper_device;
    if (queue)   clReleaseCommandQueue(queue);
    if (context) clReleaseContext(context);
  }
};

