library(OpenCLeaR)

if (!EnsureOpenclInitialized()) {
    tinytest::exit_file("OpenCL infrastructure not available on this host")
} else {
    ActivateDevice(0)
}

inline::registerPlugin("inlineCxxPlugin", OpenCLeaR::inlineCxxPlugin())
inline::registerPlugin("inlineCxxPluginFloat", OpenCLeaR::inlineCxxPluginFloat())
inline::registerPlugin("inlineCxxPluginDouble", OpenCLeaR::inlineCxxPluginDouble())
