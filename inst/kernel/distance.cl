__kernel void distance_matrix(
                              __global real_t* output,
                              __global real_t* input,
                              const int N,
                              const int DIM){

  size_t flat_id = get_global_id(0);

  // Mathematische Matrix-Rekonstruktion
  size_t i = flat_id % N; 
  size_t j = flat_id / N; 

  if (i < N && j < N) {
    // 🎯 Hauptdiagonale initialisieren (Nutzt nackte 0 statt 0.0f!)
    if (i == j) {
      output[j * N + i] = 0;
      return;
    }
    
    // Symmetrie ausnutzen
    if (j < i) {
      real_t tmpRes = 0; // 🎯 Dynamische 0 statt hartes 0.0f!
      for (int k = 0; k < DIM; ++k) {
        real_t diff = input[i + k * N] - input[j + k * N];
        tmpRes += diff * diff;
      }
      tmpRes = sqrt(tmpRes);
      
      output[j * N + i] = tmpRes; 
      output[i * N + j] = tmpRes; 
    }
  }
}
