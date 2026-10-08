#include "CLpp.hpp"

#include <fstream>
#include <sstream>
#include <string>
#include <vector>
#include <iostream>



namespace backend {
  // Globale Variable zur Entkopplung des Pfads beim Paketstart
  std::string global_temporary_kernel_path = "";

  CLpp::CLpp() {
    // Standardkonstruktor bleibt für den Erfolgsfall leer, 
    // da setupDevices() die Arbeit übernimmt.
  }

  CLpp::CLpp(bool dummy_mode) {
    // Macht absolut gar nichts. Verhindert jeden OpenCL-Aufruf.
    this->is_initialized = false;
  }

  bool CLpp::setupDevices() {
    this->kernel_path = global_temporary_kernel_path;
    try {
      this->activeDevice = Device(select_device_with_id(0L), this->collect_opencl_c_code());

      // Überprüfung auf virtuelles Dummy-Gerät
      if (this->activeDevice.info.name == "NULL device" || this->activeDevice.info.vendor == "Nobody") {
        this->is_initialized = false;
        return false; 
      }

      this->is_initialized = true;
      return true;
    } catch (...) {
      this->is_initialized = false;
      return false;
    }
  }
  
  void CLpp::info() {
  //  std::cout << "name: " << this->activeDevice.info.name << std::endl;
  //  std::cout << "fp64: " << this->activeDevice.info.is_fp64_capable << std::endl;
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
  void CLpp::activateDeviceWithIndex(int id){
    this->activeDevice = Device(select_device_with_id(id), this->collect_opencl_c_code());
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
    this->kernel_path = str;
  }

  // Holt den Getter mitsamt der Thread-Sperre zurück in den physischen Quellcode!
  std::string CLpp::getKernelsPath() const {
    std::lock_guard<std::mutex> lock(mutex);
    return this->kernel_path;
  }

  CLpp::~CLpp() {}

  CLpp& CLpp::instance() {
  static CLpp* inst = nullptr;
  if (inst == nullptr) {
    // 1. Erstelle das Objekt direkt im normalen Modus
    inst = new CLpp(); 
    
    // 2. Versuche die Hardware zu aktivieren.
    // Sollte der interne Wrapper rekursiv instance() aufrufen, sieht er, 
    // dass inst != nullptr ist, und läuft nicht in eine Endlosschleife!
    if (inst->setupDevices()) {
      // ERFOLG (z.B. auf Ihrem Linux-Rechner): 
      // Das Objekt bleibt bestehen und ist voll einsatzbereit!
      std::cout << "OpenCL erfolgreich initialisiert: Gerät bereit!" << std::endl;
    } else {
      // FEHLERFALL (z.B. im treiberlosen Docker-Container):
      // Lösche das fehlerhafte Objekt und ersetze es durch den sicheren Dummy
      delete inst;
      inst = new CLpp(true);
      std::cout << "OpenCL Fallback aktiviert: Sicheres Dummy-Objekt wird genutzt." << std::endl;
    }
  }
  return *inst;    
}

  
}
