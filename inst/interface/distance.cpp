    // 1. R-Argumente einlesen
    NumericMatrix r_mat(mat);
    int nr = r_mat.nrow();
    int nc = r_mat.ncol();
    
    int nin  = nc * nr;
    int nout = nr * nr;
    int total_threads = nout; 

    // 2. Allokationsfreier Hardware-Tunnel
    Memory<real_t> Input(*device, nin);
    Memory<real_t> Output(*device, nout);

    for (int i = 0; i < nin; ++i) {
        Input[i] = (real_t)r_mat[i];
    }
    Input.write_to_device();

    // 3. JIT-TREIBER-EINSTELLUNGEN FÜR DAS MINI-BEISPIEL
    // Wir setzen den Pfad für die libkernel.cl bewusst auf leer (""), 
    // damit das Backend die Einbindung komplett überspringt!
    device->set_math_library_path(""); 
    
    device->set_kernel_file("distance.cl");
    device->set_kernel_name("distance.cl");
    device->initialize_binary_cache_path();
    device->load_or_build_kernel();

    // 4. KERNEL STARTEN
    Kernel distance_kernel(*device, total_threads, "distance_matrix", Output, Input, nr, nc);
    distance_kernel.run();

    // 5. DATEN DIREKT ZURÜCKLESEN
    Output.read_from_device();

    NumericMatrix res_matrix(nr, nr);
    for (int i = 0; i < nout; ++i) {
        res_matrix[i] = (double)Output[i];
    }

    return wrap(res_matrix);
