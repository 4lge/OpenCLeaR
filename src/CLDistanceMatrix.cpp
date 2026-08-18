
#include <Rcpp.h>

#include "backend/init.hpp"

#include "backend/include/backend/distance_matrix.hpp"

using namespace Rcpp;

// [[Rcpp::export]]
NumericMatrix CLDistanceMatrix(const NumericMatrix& mat) {
    IntegerVector dim = mat.attr("dim");
    int rows = dim[0], cols = dim[1];

    std::vector<double> input(mat.begin(), mat.end());
    std::vector<double> output(rows * rows, 0);

    backend::distance_matrix(input.data(), rows, cols, output.data());

    NumericMatrix outmat(rows, rows);
    std::copy(output.begin(), output.end(), outmat.begin());

    return outmat;
}

