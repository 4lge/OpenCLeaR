

rnormCLinline <- inline::cxxfunction(signature(n = "integer", mean = "numeric", sd = "numeric"),
     "using namespace backend;
     // We get the address of the device reference and convert it using const_cast den benötigten Schreib-Zeiger!
     Device* device = const_cast<Device*>(&getActiveDeviceFromBackend());

      Rcpp::Function sys_file(\"system.file\");
      std::string pkg_kernel_dir = Rcpp::as<std::string>(sys_file(\"kernel\", Rcpp::Named(\"package\") = \"OpenCLeaR\"));
                                           

            device->set_kernel_path(pkg_kernel_dir);
            device->set_kernel_file(\"rnorm.cl\");
                                        device->set_kernel_name(\"rnorm.cl\");
                                        device->initialize_binary_cache_path();
                                         device->set_math_library_path(pkg_kernel_dir  + \"libkernel.cl\");
     std::cout << \"compile code :\\n\" << device->get_compiled_code() << \"\\n ---- \\n\" << std::endl;

     std::cout << \"kernel code :\\n\" << device->get_kernel_code() << \"\\n ---- \\n\" << std::endl;


     // copy data from host memory to device memory
     Memory<int>    Seed(*device, 1);
     Memory<double> OutputD;
     Memory<float>  OutputF;
     int N=as<int>(n);
     NumericVector output(N);

     Environment e = Environment::global_env();
     std::vector<int> seed = e[\".Random.seed\"];
     Seed[0]=seed[seed[1]+1];
     Seed.write_to_device();

    Kernel norm_rng;
    // kernel that runs on the device
    if(device->info.is_fp64_capable){ // TODO: use float via parameter also on double device via argument.
      OutputD = Memory<double>(*device, N);
      norm_rng = Kernel(*device, N, \"norm_rng\", OutputD, Seed, as<double>(mean), as<double>(sd));
    } else {
      OutputF = Memory<float>(*device, N);
      norm_rng = Kernel(*device, N, \"norm_rng\", OutputF, Seed, as<float>(mean), as<float>(sd));
    }
    // copy data from host memory to device memory

    //Seed.read_from_device();
    //e[\".Random.seed\"][1]=Seed[0];
    // waste a single random number in R to update .Random.seed
    Function f(\"runif\");
    SEXP r=f(1);

    // run kernel on the device
    norm_rng.run();

    // copy data from device memory to host memory
    if(device->info.is_fp64_capable){
      OutputD.read_from_device();
      for(auto i=0; i<OutputD.length(); i++)
        output[i] = OutputD[i];
    } else {
      OutputF.read_from_device();
      for(auto i=0; i<OutputF.length(); i++)
        output[i] = (double)OutputF[i];
    }
    return wrap(output);
",
plugin = "OpenCLeaR",
verbose=TRUE)

rnormCLinline(42,0,1)
