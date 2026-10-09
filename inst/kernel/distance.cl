
__kernel void distance_matrix(
                              __global real_t* output,
                              __global real_t* input,
                              const int N,
                              const int DIM){

  size_t flat_id = get_global_id(0);

  // Mathematische Matrix-Rekonstruktion (Fortran-Style Leading Dimension)
  size_t i = flat_id % N; // Zeilen-Index
  size_t j = flat_id / N; // Spalten-Index

  if (i < N && j < N) {
    // Hauptdiagonale initialisieren
    if (i == j) {
      output[j * N + i] = (real_t)0.0;
      return;
    }
    
    // Symmetrie ausnutzen: Nur im unteren Dreieck die Schleife rechnen!
    if (j < i) {
      real_t tmpRes = (real_t)0.0;
      for (int k = 0; k < DIM; ++k) {
        real_t diff = input[i + k * N] - input[j + k * N];
        tmpRes += diff * diff;
      }
      tmpRes = sqrt(tmpRes);
      
      // 🍏 SYMMETRISCHES SCHREIBEN: Ein Thread füllt beide Hälften bytesynchron aus!
      output[j * N + i] = tmpRes; // Unteres Dreieck
      output[i * N + j] = tmpRes; // Oberes Dreieck
    }
  }
}
