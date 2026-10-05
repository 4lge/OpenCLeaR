#include <Rcpp.h>
#include "backend/init.hpp"
#include "backend/CLpp.hpp"
#include "utilities.hpp"
#include <thread>
#include <chrono>
#include <atomic>
#include <R.h> // Wichtig für R_CheckUserInterrupt()
#include "device.hpp"


using namespace Rcpp;

// 🚀 DIE COOLE C-LEITUNG:
// Deklariert die freie Funktion aus der init.cpp, damit Rcpp sie blind versteht!
extern "C" std::string getKernelsPathFromBackend();


//' Activate OpenCL devive with maximum FLOPS
//'
//' Automatically chooses the device with maximum FLOPS.
//' @note This is the default activation method.
//' @export
// [[Rcpp::export]]
void ActivateDeviceWithMostFlops() {
  backend::activateDeviceWithMostFlops();
  backend::sync_global_device();
}

//' Activate OpenCL devive with maximum memory
//'
//' Automatically chooses the device with maximum memory.
//' @export
// [[Rcpp::export]]
void ActivateDeviceWithMostMemory() {
  backend::activateDeviceWithMostMemory();
  backend::sync_global_device();
}

//' Activate OpenCL devive by ID
//' @param id id of device, all devices will be shown on load ofthe
//'     library.
//' @export
// [[Rcpp::export(name = "ActivateDeviceWithID_Native")]]
void ActivateDeviceWithID_Native(int id) {
    // 🚀 ALTE COCKPIT-BLOCKADE RESTLOS GEBRANNT:
    // Der fehlerhafte ID-Check fliegt komplett raus!
    
    // Vorbereitung für den sauberen Treiberwechsel im RAM
    global_opencl_device = nullptr;

    // Das C++ Backend schaltet die Hardware frisch und hängerfrei um
    backend::CLpp::instance().activateDeviceWithID(id);
    
    // Synchronisiert den globalen C-Pointer für Rcpp frisch an die neue Adresse
    backend::sync_global_device();     
}

//' OpenCL asynchronous device activation routine to break Windows WDDM context lock
//' @export
// [[Rcpp::export(name = "ActivateDeviceWithID_Async", rng = FALSE)]]
bool ActivateDeviceWithID_Async(int id) {
  std::atomic<bool> is_done(false);
  std::atomic<bool> success(false);

  // 🚀 DER WORKER-THREAD: Holt sich das Objekt und feuert die Methode per Pfeil -> ab!
  std::thread cl_activate_thread([&is_done, &success, id]() {
    try {
      backend::activateDeviceWithID(id);

      success = true;
    } catch (...) {
      success = false;
    }
    is_done = true; // Dem R-Hauptthread signalisieren, dass der Kontext im RAM steht!
  });

  // 🔄 DER BLOCKFREIE ATEM-LOOP IM R-HAUPTTHREAD:
  // Hält R in Nanosekunden-Takt am Leben und hebelt die Windows-WDDM-Sperre aus!
  while (!is_done) {
    std::this_thread::sleep_for(std::chrono::milliseconds(5));

#ifdef _WIN32
    // Zwingt Windows im 5ms-Takt zum Thread-Wechsel, bevor das System einfriert!
    R_CheckUserInterrupt();
#endif
  }

  // Den Thread sauber wieder einsammeln
  if (cl_activate_thread.joinable()) {
    cl_activate_thread.join();
  }

  // 🔄 4. DIE GLOBALE SYNCHRONISATION (Sicher im Hauptthread platziert!)
  if (success) {
    backend::sync_global_device();
  }

  return success;
}

//' OpenCL initialization routine
//'
//' to be called via onLoad mechanism.
//' @export
// [[Rcpp::export]]
bool InitCL() {
  // 🔐 Ein atomares Flag, um die Thread-Synchronisation abzusichern
  std::atomic<bool> is_done(false);
  std::atomic<bool> success(false);

  // 🚀 DER WORKER-THREAD (Die opencltools-Strategie):
  // Wir forken die blockierende Initialisierung komplett aus dem R-Scope heraus!
  std::thread cl_init_thread([&]() {
    try {
      // Hier stehen Ihre originalen Backend-Aufrufe:
      backend::initCL();
      //NumericVector rand_init=runif(1, 0.0, 1.0);
      success = true;
    } catch (...) {
      success = false;
    }
    is_done = true; // Dem R-Hauptthread signalisieren, dass wir durch sind
  });

  // 🔄 DER BLOCKFREIE ATEM-LOOP IM R-HAUPTTHREAD:
  // R bleibt hellwach, verarbeitet Signale und wird von Windows niemals blockiert!
  while (!is_done) {
    // 1. Dem Windows-Scheduler 10 Millisekunden Zeit geben, den Hintergrund-Thread zu füttern
    std::this_thread::sleep_for(std::chrono::milliseconds(10));

#ifdef _WIN32
    // 2. Der R-Event-Schleife explizit Luft zum Atmen geben.
    // Das bricht den Windows-WDDM-Busy-Waiting-Deadlock sofort auf!
    R_CheckUserInterrupt();
#endif
  }

  // Den Hintergrund-Thread wieder sauber einsammeln, um RAM-Lecks zu vermeiden
  if (cl_init_thread.joinable()) {
    cl_init_thread.join();
  }

  return success;
}


//' OpenCL initialization routine
//'
//' called via onLoad mechanism.
//' @param kernelsPath string, contains path to load OpenCL kernels from.
//' @export
// [[Rcpp::export(name = "SetKernelsPath", rng = FALSE)]]
void SetKernelsPath(String kernelsPath) {
  std::string path = kernelsPath.get_cstring();
  backend::setKernelsPath(path);
  if (!opencl_bridge_established) {
    // 🚀 INITIAL-ZÜNDUNG: Das beim onLoad eingerichtete Gerät wird global scharfgeschaltet!
    backend::sync_global_device();
    opencl_bridge_established = true;
  }
}

//' @export
// [[Rcpp::export(name = "IsOpenCLReady", rng = FALSE)]]
bool IsOpenCLReady() {
  return backend::CLpp::instance().isInitialized();
}



//' Schaltet die detaillierte OpenCL-Diagnose und Hardware-Tabellen im Terminal ein oder aus
//' @param state bool, TRUE zum Einschalten, FALSE zum Stummschalten
//' @export
// [[Rcpp::export(name = "ToggleOpenCLPrint", rng = FALSE)]]
void ToggleOpenCLPrint(bool state) {
  // 🚀 Schreibt den neuen Wert direkt über die Referenz in das C++11-Singleton!
  get_opencl_print_enabled() = state;
}


// [[Rcpp::export(name = ".GetActiveDeviceInfo_cpp", rng = FALSE)]]
List GetActiveDeviceInfo() {
  // 🚀 SCHUTZGÜRTEL 1: Verhindert den Segfault, falls der User noch kein Gerät aktiviert hat!
  if (global_opencl_device == nullptr) {
    warning("⚠ [OpenCLeaR] Kein OpenCL-Gerät aktiv! Bitte führe zuerst ActivateDeviceWithID(0) aus.");

    // Gibt eine leere Liste mit Dummy-Werten zurück, damit R sauber weiterläuft
    return List::create(
                        _["ID"] = -1,
                        _["Name"] = "Nicht gebunden (Bitte ActivateDeviceWithID ausführen)",
                        _["Vendor"] = "Keiner",
                        _["FP64_Capable"] = false
                        );
  }
  // Wir greifen direkt auf die info-Struktur Ihres globalen Speicherankers zu!
  // Da dieses Objekt im RAM mitsynchronisiert wird, stehen hier immer die
  // Daten der exakt ausgewählten Karte (NVIDIA, Intel oder CPU) drin.

  //const auto& d = backend::getActiveDeviceFromBackend().info;
  const auto& d = global_opencl_device->info;

  // Betriebssystem-String analog zu Ihrem Wrapper ermitteln
#if defined(_WIN32)
  const std::string os = "Windows";
#elif defined(__linux__)
  const std::string os = "Linux";
#elif defined(__APPLE__)
  const std::string os = "macOS";
#else
  const std::string os = "unknown";
#endif

  // Wir schnüren alle Werte zu einer wunderschönen, nativen R-Liste zusammen!
  return List::create(
                      _["ID"]             = d.id,
                      _["Platform_ID"]   = global_opencl_device->platform_id(), 
                      _["Device_ID"]     = global_opencl_device->device_id(),  
                      _["Name"]           = d.name,
                      _["Vendor"]         = d.vendor,
                      _["OS"]             = os,
                      _["Driver_Version"] = d.driver_version,
                      _["OpenCL_Version"] = "OpenCL C " + d.opencl_c_version,
                      _["Compute_Units"]  = d.compute_units,
                      _["Clock_MHz"]      = d.clock_frequency,
                      _["Cores"]          = d.cores,
                      _["TFLOPs"]         = d.tflops,
                      _["Memory_MB"]      = d.memory,
                      _["Uses_RAM"]       = d.uses_ram,
                      _["Global_Cache_KB"]= d.global_cache,
                      _["Local_Cache_KB"] = d.local_cache,
                      _["Max_Buffer_MB"]  = d.max_global_buffer,
                      _["Max_Constant_KB"]= d.max_constant_buffer,
                      _["FP64_Capable"]   = d.is_fp64_capable
                      );
}

// [[Rcpp::export(name = ".is_device_bound_cpp", rng = FALSE)]]
bool is_device_bound() {
    // Liefert einfach nur TRUE oder FALSE, ohne jemals eine Warnung zu triggern!
    return (global_opencl_device != nullptr);
}

// [[Rcpp::export(name = ".GetDeviceList_cpp", rng = FALSE)]]
DataFrame GetDeviceList() {
  // 1. 🚀 DIE REINE WAHRHEIT: Wir rufen deine originale, bereinigte Wrapper-Funktion auf!
  std::vector<Device_Info> devices = get_devices(false);

  // Rcpp-Vektoren für die DataFrame-Spalten vorbereiten
  IntegerVector device_ids;
  IntegerVector platform_ids; // 🚀 NEU
  IntegerVector hardware_device_ids; // 🚀 NEU
  CharacterVector device_names;
  CharacterVector device_vendors;
  NumericVector compute_units;
  NumericVector clock_mhz;
  NumericVector cores_count;
  NumericVector tflops_perf;
  NumericVector vram_mb;
  LogicalVector fp64_capable;

  // 2. Wir loopen flach über den fertigen Vektor
  for (size_t i = 0; i < devices.size(); ++i) {
    const auto& d = devices[i];

    // Daten aus der fertig befüllten Struktur absaugen
    device_ids.push_back(d.id);
    platform_ids.push_back(d.platform_idx); // 🎯 Holt den echten Plattform-Index
    hardware_device_ids.push_back(d.device_idx); // 🎯 Holt den echten Treiber-Device-Index
    device_names.push_back(d.name);
    device_vendors.push_back(d.vendor);
    compute_units.push_back(d.compute_units);
    clock_mhz.push_back(d.clock_frequency);
    cores_count.push_back(d.cores);
    tflops_perf.push_back(d.tflops);
    vram_mb.push_back(d.memory);
    fp64_capable.push_back(d.is_fp64_capable);
  }

  // 3. Zum nativen R-DataFrame verschmelzen (mitsamt den neuen Treiberspalten!)
  return DataFrame::create(
                           _["ID"]            = device_ids,
                           _["Platform_ID"]   = platform_ids, // 🚀 JETZT VORHANDEN!
                           _["Device_ID"]     = hardware_device_ids, // 🚀 JETZT VORHANDEN!
                           _["Name"]          = device_names,
                           _["Vendor"]        = device_vendors,
                           _["Compute_Units"] = compute_units,
                           _["Clock_MHz"]     = clock_mhz,
                           _["Cores"]         = cores_count,
                           _["TFLOPs"]        = tflops_perf,
                           _["VRAM_MB"]       = vram_mb,
                           _["FP64_Capable"]  = fp64_capable,
                           _["stringsAsFactors"] = false
                           );
}
// 🚀 NEU: Ermöglicht R das blockfreie Auslesen des internen Kernel-Pfads
// [[Rcpp::export(name = ".GetKernelsPath_cpp", rng = FALSE)]]
std::string GetKernelsPath() {
  // Wir holen uns den Pfad direkt und blockfrei aus der zentralen Instanz!
  return getKernelsPathFromBackend();
}

//' Get kernel code as seen by OpenCL
//'
//' @export
// [[Rcpp::export(name = "GetKernelCode", rng = FALSE)]]
String GetKernelCode() {
  // 🚀 1. Zeiger auf das aktive, wache Gerät aus dem Backend holen
  Device* device = const_cast<Device*>(&backend::getActiveDeviceFromBackend());

  // 🚀 2. Die Methode direkt über das Objekt aufrufen (da sie ein Member von Device ist!)
  std::string code = device->get_kernel_code();
  return wrap(code);
}
