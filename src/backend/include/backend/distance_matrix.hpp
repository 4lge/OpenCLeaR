#pragma once

#include "CL_context.hpp"
#include "backend/export.hpp" // Holt die Definitionen
#include "cl_error_lookup.hpp"
#include "OpenCL-Wrapper/opencl.hpp"

#include <iostream>
#include <fstream>
#include <sstream>
#include <vector>
#include <algorithm>

namespace backend {

	/**
	 * 	FUNCTION TO CALCULATE THE DISTANCE MATRIX OF data AND WRITE IT INTO res.
	 * 
	 * 	data is a 1d array of length rows * cols.
	 * 	res is a 1d array of length rows * rows.
	 */
	 EXPORT int distance_matrix(const std::vector<double>& data, const int rows, const int cols, std::vector<double>& res);

}
