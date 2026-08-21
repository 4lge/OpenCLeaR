
#include <Rcpp.h>

#include "backend/init.hpp"

using namespace Rcpp;

// [[Rcpp::export]]
SEXP SetKernelsPath(String kernelsPath) {
    std::string path = kernelsPath;
    backend::set_kernels_path(path);
    return R_NilValue;
}

