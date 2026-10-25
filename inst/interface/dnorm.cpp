// Rcpp function body

// 1. Eingaben aus R einlesen (gemäß Signatur in oclFunction)
NumericVector r_x     = as<NumericVector>(x);
real r_mean         = as<real>(mean);
real r_sd           = as<real>(sd);

int r_n = r_x.size();

// 2. Ziel-Variable für Rcpp reservieren
NumericVector r_dnorm(r_n);

// 3. OpenCL-Speicherstrukturen (Buffer) auf dem Gerät anlegen
// Wir brauchen einen Read-Only Input-Buffer für x und einen Output-Buffer
Memory<real> Input(*device, r_n);
Memory<real> Output(*device, r_n);

// 4. Input-Daten von Rcpp in den OpenCL-Buffer kopieren
for(int i = 0; i < r_n; ++i) {
  Input[i] = r_x[i];
}

// 5. Den Input-Buffer physisch auf die GPU hochladen
Input.write_to_device();

// 6. Den Kernel instanziieren (Name, Output, Input, Parameter)
// Übergibt globale Work-Size (r_n), Kernel-Name ("dnorm") und die Argumente
Kernel dnorm(*device, r_n, "norm_pdf", Output, Input, r_mean, r_sd);

// 7. 🔥 Kernel-Ausführung auf der GPU starten
dnorm.run();

// 8. Ergebnis-Buffer von der GPU zurück in den Host-RAM holen
Output.read_from_device();

// 9. Daten aus dem OpenCL-Speicher in den Rcpp-Rückgabe-Vektor schreiben
for(int i = 0; i < r_n; ++i) {
  r_dnorm[i] = Output[i];
}

// 10. Berechnete Dichten an R zurückgeben
return r_dnorm;
