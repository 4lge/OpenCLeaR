// Rcpp function body

// 1. Eingaben aus R einlesen (Vektor q und die Parameter)
NumericVector r_q   = as<NumericVector>(q);
real r_min          = as<real>(min);
real r_max          = as<real>(max);

int r_n = r_q.size();

// 2. Ziel-Variable für den Rcpp-Rückgabe-Vektor reservieren
NumericVector r_punif(r_n);

// 3. OpenCL-Speicherstrukturen (Buffer) auf dem Gerät anlegen
Memory<real> Input(*device, r_n);
Memory<real> Output(*device, r_n);

// 4. Input-Daten von Rcpp in den OpenCL-Buffer kopieren
for(int i = 0; i < r_n; ++i) {
  Input[i] = r_q[i];
}

// 5. Den Input-Buffer physisch auf die GPU hochladen
Input.write_to_device();

// 6. Den Kernel instanziieren (Einstiegspunkt: "unif_cdf")
Kernel punif_kernel(*device, r_n, "unif_cdf", Output, Input, r_min, r_max);

// 7. 🔥 Kernel-Ausführung auf der GPU starten
punif_kernel.run();

// 8. Ergebnis-Buffer von der GPU zurück in den Host-RAM holen
Output.read_from_device();

// 9. Daten aus dem OpenCL-Speicher in den Rcpp-Rückgabe-Vektor schreiben
for(int i = 0; i < r_n; ++i) {
  r_punif[i] = Output[i];
}

// 10. Berechnete Wahrscheinlichkeiten an R zurückgeben
return r_punif;
