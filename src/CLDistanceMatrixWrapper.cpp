
#include <Rcpp.h>

#include "backend/init.hpp"

#include "backend/include/backend/distance_matrix.hpp"

using namespace Rcpp;

// [[Rcpp::export]]
NumericMatrix CLDistanceMatrixWrapper(const NumericMatrix& mat) {
    int rows = mat.nrow();
    int cols = mat.ncol();

    // 🚀 Rcpp erstellt die Zielmatrix absolut standardkonform im R-Speicherraum
    NumericMatrix outmat(rows, rows);

    // 🍏 DIE PERFEKTE BRÜCKE: 
    // mat.begin() liefert den direkten double* Zeiger auf die R-Eingangsdaten.
    // outmat.begin() liefert den direkten double* Zeiger auf den R-Ausgangsspeicher.
    // Es wird im CPU-RAM absolut nichts kopiert, verschoben oder allokiert!
    backend::distance_matrix(mat.begin(), rows, cols, outmat.begin());

    // Rcpp gibt die befüllte Matrix typsicher und elegant an R zurück
    return outmat;
}

