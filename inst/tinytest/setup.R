library(OpenCLeaR)

if (!EnsureOpenclInitialized()) {
    tinytest::exit_file("OpenCL infrastructure not available on this host")
} else {
    if (identical(Sys.getenv("_R_CHECK_CRAN_INCOMING_"), "true")) {
       tinytest::exit_file("Skipping time-intensive C++ OpenCL tests during CRAN incoming checks.")
    }
    ActivateDevice(0)
}

inline::registerPlugin("inlineCxxPlugin", OpenCLeaR::inlineCxxPlugin())
inline::registerPlugin("inlineCxxPluginFloat", OpenCLeaR::inlineCxxPluginFloat())
inline::registerPlugin("inlineCxxPluginDouble", OpenCLeaR::inlineCxxPluginDouble())
