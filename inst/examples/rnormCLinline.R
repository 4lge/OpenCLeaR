# if (requireNamespace("RcppArmadillo")) {
# 	
#     fx <- cxxfunction(signature(x = "integer", y = "numeric"),
#                       "int dim = as<int>(x);
# 		       arma::mat z = as<double>(y) * arma::eye<arma::mat>(dim, dim);
# 		       return wrap(arma::accu(z));",
#                       plugin = "RcppArmadillo",
#                       verbose=TRUE)
#     fx(2L, 5)
# }

rnormCLinlineFiles <- inline::cxxfunction(signature(n = "integer", mean = "numeric", sd = "numeric"),"inst/examples/kernels/distance.cl","inst/interface/idw_rcpp.cpp",plugin = "OpenCLeaR",debug=TRUE,verbose=TRUE)



rnormCLinline <- inline::cxxfunction(signature(n = "integer", mean = "numeric", sd = "numeric"),
    "using namespace backend;
        // 🚀 DIE ABSOLUTE FINALE ZEIGER-RETTUNG:
        //  Wir holen die Adresse der Referenz und wandeln sie per const_cast in den benötigten Schreib-Zeiger!
     Device* device = const_cast<Device*>(&getActiveDeviceFromBackend());

     
    std::string base = backend::CLpp::instance().getKernelsPath();

    if (!base.empty() && base.back() != '/') {
      base += \"/\";
    }

    device->set_kernel_path(base);
    device->set_kernel_file(\"rnorm.cl\");
    device->set_kernel_name(\"rnorm.cl\"); // fixme
    device->initialize_binary_cache_path();
    std::string math_lib_file = base + \"libkernel.cl\";
    device->set_math_library_path(math_lib_file);

    std::string compiler_folder = base;
    size_t kernels_pos = compiler_folder.rfind(\"kernels\");

    if (kernels_pos != std::string::npos) {
      compiler_folder = compiler_folder.substr(0, kernels_pos) + \"bin\";
    } else {
      compiler_folder = \"./bin\";
    }

    device->set_compiler_path(compiler_folder);

    // 🚀 EIN EINZIGER BEFEHL: Erledigt alles im Backend sychron und prozess-isoliert!
    device->load_or_build_kernel();

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
