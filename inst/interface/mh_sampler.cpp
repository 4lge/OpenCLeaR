    int total_samples = as<int>(n_samples);
    int chains        = as<int>(n_chains);
    int samples_per_chain = total_samples / chains;

    NumericVector r_data(data_vector);
    int data_len = r_data.size();
    int total_output_size = chains * samples_per_chain;

    NumericVector out_mu(total_output_size);
    NumericVector out_sigma(total_output_size);

    Environment e = Environment::global_env();
    std::vector<int> r_seed = e[".Random.seed"];
    int base_seed = r_seed[r_seed[1] + 1];

    // Hardware-Puffer füttern (device wird vollautomatisch von generateInlineCL injiziert!)
    Memory<real_t> GpuData(*device, data_len);
    Memory<real_t> GpuMu(*device, total_output_size);
    Memory<real_t> GpuSigma(*device, total_output_size);
    Memory<int>    GpuSeeds(*device, chains);

    for(int i=0; i<data_len; ++i) GpuData[i] = (real_t)r_data[i];
    for(int i=0; i<chains; ++i)   GpuSeeds[i] = base_seed + (i * 777);

    GpuData.write_to_device();
    GpuSeeds.write_to_device();

    real_t mu_init_typed       = as<real_t>(mu_init);
    real_t sigma_init_typed    = as<real_t>(sigma_init);
    real_t prop_sd_mu_typed    = (real_t)0.05;
    real_t prop_sd_sigma_typed = (real_t)0.05;
    Kernel mh_kernel(*device, chains, "mh_sampler_kernel", 
                     GpuMu, GpuSigma, GpuData, data_len, samples_per_chain,
                     mu_init_typed, sigma_init_typed, prop_sd_mu_typed,  prop_sd_sigma_typed , GpuSeeds);

    // 🔥 FEUER FREI AUF DER GPU 🔥
    mh_kernel.run();

    GpuMu.read_from_device();
    GpuSigma.read_from_device();

    for(int i=0; i<total_output_size; ++i) {
        out_mu[i]    = GpuMu[i];
        out_sigma[i] = GpuSigma[i];
    }

    Function f("runif"); f(1);

    return List::create(
        _["mu"]    = out_mu,
        _["sigma"] = out_sigma
    );
