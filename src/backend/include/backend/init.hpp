#pragma once

#include <string>

#ifndef PLUGIN
#include "backend/export.hpp"
#else
#include "export.hpp"
#endif
#include "OpenCL-Wrapper/opencl.hpp"

namespace backend {

	/**
	 * 	Attaches a kernel path to the static linkage OpenCL state singleton.
	 */
	extern "C" EXPORT void set_kernels_path(const std::string& path);

}
