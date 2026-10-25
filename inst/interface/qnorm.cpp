// Rcpp function body

// 1. Eingaben aus R einlesen (Passend zur Signatur im oclFunction-Aufruf)
NumericVector r_p     = as<NumericVector>(p);
real r_mean         = as<real>(mean);
real r_sd           = as<real>(sd);

int r_n = r_p.size();

// 2. Ziel-Variable für den Rcpp-Rückgabe-Vektor reservieren
NumericVector r_qnorm(r_n);

// 3. OpenCL-Speicherstrukturen (Buffer) auf dem Gerät anlegen
Memory<real> Input(*device, r_n);
Memory<real> Output(*device, r_n);

// 4. Input-Daten von Rcpp in den OpenCL-Buffer kopieren
for(int i = 0; i < r_n; ++i) {
  Input[i] = r_p[i];
}

// 5. Den Input-Buffer physisch auf die GPU hochladen
Input.write_to_device();

// 6. Den Kernel instanziieren (Nutzt jetzt "qnorm_kernel" als Einstiegspunkt!)
Kernel qnorm(*device, r_n, "norm_q", Output, Input, r_mean, r_sd);

// 7. 🔥 Kernel-Ausführung auf der GPU starten
qnorm.run();

// 8. Ergebnis-Buffer von der GPU zurück in den Host-RAM holen
Output.read_from_device();

// 9. Daten aus dem OpenCL-Speicher in den Rcpp-Rückgabe-Vektor schreiben
for(int i = 0; i < r_n; ++i) {
  r_qnorm[i] = Output[i];
}

// 10. Berechnete Quantile an R zurückgeben
return r_qnorm;
