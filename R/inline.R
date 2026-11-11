##' inline plugin
##'
##' @rdname inline
##' @param ... Further arguments passed to the in line plugin.
##' @details It is possible to access your own kernel via the inline() mechanism:
##'
##' 1. Write a kernel = *.cl file and announce its location via SetKernelsPath()
##'
##' 2. Write an interface using Rcpp for data exchange with R and OpenCL-Wrapper classes (Memory, Device, ...) with the OpenCL backend
##'
##' 3. Compile and run it with inline() using the provided plugin
##' @note
##' If you use the generic plugin \code{inclineCxxPlugin} you have to
##' take care about the float/double characteristics on your own.
##' You can force the use of float or double by choosing
##' \code{inclineCxxPluginFloat} or  \code{inclineCxxPluginDouble} explicitely
##' while using \code{real} as automatically generated typedef both in your CL and
##' C++ code. An esier way is to use \code{inlineCL} which automates to inline call or
##' even \code{oclFunction} which completely automates this task and adapts on the fly to your
##' OpenCL device.
##' @examples
##' \dontrun{
##' source(paste(system.file("examples", package = "OpenCLeaR"),"rnormCLinline.R",sep="/"))
##' }
##' @export
inlineCxxPlugin <- function(...) {
    sys_name <- Sys.info()[["sysname"]]
    pkg_lib_dir <- system.file("lib", package = "OpenCLeaR")

    if (.Platform$OS.type == "windows") {
        ##  Windows: Static linking, NO rpath!
        linker_flags <- paste(" -L", system.file("libs", package = "OpenCLeaR"), " -l:BACKEND.a ", " -L", system.file("libs/x64", package = "OpenCLeaR")," -lOpenCL", sep="")
    } else if (sys_name == "Darwin") {
        ## macOS: Link against the 'lib' path and use macOS rpath
        linker_flags <- paste(" -Wl,-rpath,", pkg_lib_dir, " -L", pkg_lib_dir, " -lBACKEND -framework OpenCL", sep="")
    } else {
        ## Linux: Link against the 'lib' path and use Linux rpath
        linker_flags <- paste(" -Wl,-rpath,", pkg_lib_dir, " -L", pkg_lib_dir, " -lBACKEND -lOpenCL", sep="")
    }

    plugin <- Rcpp::Rcpp.plugin.maker(
                        include.before = "#include \"CLpp.hpp\"\n#include \"init.hpp\"\nstatic std::string global_math_library_code = \"\\n\"; inline std::string get_opencl_c_code() { return global_math_library_code; }\n",
                        libs           = linker_flags,
                        package        = "OpenCLeaR"
                    )
    settings <- plugin()
    if (.Platform$OS.type == "windows") {
        settings$env$PKG_CXXFLAGS <- paste(settings$env$PKG_CXXFLAGS, " -mstackrealign ", sep="")
    }

    ## Add flags for output suppression to the CPPFLAGS to mute opencl.hpp
    ## and use Rcpp::Rcout for output control.
    settings$env$PKG_CPPFLAGS <- paste(
        settings$env$PKG_CPPFLAGS,
        " -DPLUGIN=1 -DOPENCLEAR_NO_OUTPUT -DOPENCLEAR_R_BUILD -I",
        system.file("include", package = "OpenCLeaR"),
        sep=""
    )

    ## Without this entry the Tinytest aborts when parsing opencl.hpp,
    ## because the compiler cannot find "Rcpp.h" in the temporary directory.
    settings$Depends <- unique(c(settings$Depends, "Rcpp"))

    return(settings)
}

##' @rdname inline
##' @export
inlineCxxPluginFloat <- function(...) {
    sys_name <- Sys.info()[["sysname"]]
    pkg_lib_dir <- system.file("lib", package = "OpenCLeaR")

    if (.Platform$OS.type == "windows") {
        ##  Windows: Static linking, NO rpath!
        linker_flags <- paste(" -L", system.file("libs", package = "OpenCLeaR"), " -l:BACKEND.a ", " -L", system.file("libs/x64", package = "OpenCLeaR")," -lOpenCL", sep="")
    } else if (sys_name == "Darwin") {
        ## macOS: Link against the 'lib' path and use macOS rpath
        linker_flags <- paste(" -Wl,-rpath,", pkg_lib_dir, " -L", pkg_lib_dir, " -lBACKEND -framework OpenCL", sep="")
    } else {
        ## Linux: Link against the 'lib' path and use Linux rpath
        linker_flags <- paste(" -Wl,-rpath,", pkg_lib_dir, " -L", pkg_lib_dir, " -lBACKEND -lOpenCL", sep="")
    }

    plugin <- Rcpp::Rcpp.plugin.maker(
                        include.before = "#include \"CLpp.hpp\"\n#include \"init.hpp\"\nstatic std::string global_math_library_code = \"\\n\";  inline std::string get_opencl_c_code() { return global_math_library_code; }\n",
                        libs           = linker_flags,
                        package        = "OpenCLeaR"
                    )
    settings <- plugin()
    if (.Platform$OS.type == "windows") {
        settings$env$PKG_CXXFLAGS <- paste(settings$env$PKG_CXXFLAGS, " -mstackrealign ", sep="")
    }
    ## Add flags for output suppression to the CPPFLAGS to mute opencl.hpp
    ## and use Rcpp::Rcout for output control.
    settings$env$PKG_CPPFLAGS <- paste(
        settings$env$PKG_CPPFLAGS,
        " -DFP64_MODE=0 -DPLUGIN=1 -DOPENCLEAR_NO_OUTPUT -DOPENCLEAR_R_BUILD -I",
        system.file("include", package = "OpenCLeaR"),
        sep=""
    )

    ## Without this entry the Tinytest aborts when parsing opencl.hpp,
    ## because the compiler cannot find "Rcpp.h" in the temporary directory.
    settings$Depends <- unique(c(settings$Depends, "Rcpp"))

    return(settings)
}

##' @rdname inline
##' @export
inlineCxxPluginDouble <- function(...) {
    sys_name <- Sys.info()[["sysname"]]
    pkg_lib_dir <- system.file("lib", package = "OpenCLeaR")

    if (.Platform$OS.type == "windows") {
        ##  Windows: Static linking, NO rpath!
        linker_flags <- paste(" -L", system.file("libs", package = "OpenCLeaR"), " -l:BACKEND.a ", " -L", system.file("libs/x64", package = "OpenCLeaR")," -lOpenCL", sep="")
    } else if (sys_name == "Darwin") {
        ## macOS: Link against the 'lib' path and use macOS rpath
        linker_flags <- paste(" -Wl,-rpath,", pkg_lib_dir, " -L", pkg_lib_dir, " -lBACKEND -framework OpenCL", sep="")
    } else {
        ## Linux: Link against the 'lib' path and use Linux rpath
        linker_flags <- paste(" -Wl,-rpath,", pkg_lib_dir, " -L", pkg_lib_dir, " -lBACKEND -lOpenCL", sep="")
    }

    plugin <- Rcpp::Rcpp.plugin.maker(
                        include.before = "#include \"CLpp.hpp\"\n#include \"init.hpp\"\nstatic std::string global_math_library_code = \"\\n\"; inline std::string get_opencl_c_code() { return global_math_library_code; }\n",
                        libs           = linker_flags,
                        package        = "OpenCLeaR"
                    )
    settings <- plugin()
    if (.Platform$OS.type == "windows") {
        settings$env$PKG_CXXFLAGS <- paste(settings$env$PKG_CXXFLAGS, " -mstackrealign ", sep="")
    }
    ## Add flags for output suppression to the CPPFLAGS to mute opencl.hpp
    ## and use Rcpp::Rcout for output control.
    settings$env$PKG_CPPFLAGS <- paste(
        settings$env$PKG_CPPFLAGS,
        " -DFP64_MODE=1 -DPLUGIN=1 -DOPENCLEAR_NO_OUTPUT -DOPENCLEAR_R_BUILD -I",
        system.file("include", package = "OpenCLeaR"),
        sep=""
    )

    ## Without this entry the Tinytest aborts when parsing opencl.hpp,
    ## because the compiler cannot find "Rcpp.h" in the temporary directory.
    settings$Depends <- unique(c(settings$Depends, "Rcpp"))

    return(settings)
}



##' Generic GPGPU JIT compiled function for OpenCL access
##'
##' @param signature Named list or vector of R arguments (like inline::cxxfunction)
##' @param kernel_file A (TODO: R-string or a) path to a *.cl file containing the GPU kernel
##' @param interface_file A (TODO: R string or a) path to a file containing the Rcpp execution code
##' @param debug Logical value. If \code{TRUE}, the complete with
##' @param math_lib Logical value. If \code{TRUE}, the mathematical library libkernel.cl is loaded.
##' @param force_float Logical value. If \code{TRUE}, execution is forced to FP32 eben on FP64 capable hardware.
##' @param ... additional arguments, passed to \code{inline::cxxfunction}.
##' @return A R function to access your CL kernel via your Rcpp interface.
##' @examples
##' \dontrun{
##' if(EnsureOpenclInitialized()){
##'# an invers distance weighting example:
##' kernel_src <- "
##' __kernel void idw_kernel(__global const real* x0, __global const real* y0, __global real* z0,
##'                          __global const real* x, __global const real* y, __global const real* z,
##'                          const int n0, const int n, const real p) {
##'     int i = get_global_id(0);
##'     if (i >= n0) return;
##'     real wsum = 0.0, num = 0.0;
##'     for (int j = 0; j < n; j++) {
##'         real d = sqrt((x0[i]-x[j])*(x0[i]-x[j]) + (y0[i]-y[j])*(y0[i]-y[j]));
##'         if (d < 1e-9) { z0[i] = z[j]; return; }
##'         real w = 1.0 / pow(d, p);
##'         wsum += w; num += w * z[j];
##'     }
##'     z0[i] = num / wsum;
##' }
##' "
##'
##' cpp_src <- "
##'     NumericVector x0(r_x0);
##'     NumericVector y0(r_y0);
##'     NumericVector x(r_x);
##'     NumericVector y(r_y);
##'     NumericVector z(r_z);
##'
##'     int n0 = x0.size();
##'     int n = x.size();
##'     NumericVector r_z0(n0);
##'
##'     Memory<real> gpu_x0(*device, n0);
##'     Memory<real> gpu_y0(*device, n0);
##'     Memory<real> gpu_z0(*device, n0);
##'     Memory<real> gpu_x(*device, n);
##'     Memory<real> gpu_y(*device, n);
##'     Memory<real> gpu_z(*device, n);
##'
##'     for(int i=0; i<n0; ++i) { gpu_x0[i] = x0[i]; gpu_y0[i] = y0[i]; }
##'     for(int j=0; j<n; ++j)  { gpu_x[j] = x[j]; gpu_y[j] = y[j]; gpu_z[j] = z[j]; }
##'
##'     gpu_x0.write_to_device(); gpu_y0.write_to_device();
##'     gpu_x.write_to_device(); gpu_y.write_to_device(); gpu_z.write_to_device();
##'
##'     Kernel k(*device, n0, \"idw_kernel\", gpu_x0, gpu_y0, gpu_z0, 
##'              gpu_x, gpu_y, gpu_z, n0, n, as<real>(p));
##'     k.run();
##'     gpu_z0.read_from_device();
##'
##'     for(int i=0; i<n0; ++i) r_z0[i] = gpu_z0[i];
##'     return r_z0;
##'"
##'
##' idw_gpu <- inlineCL(
##'     signature = signature(r_x0="numeric", r_y0="numeric", 
##'                           r_x="numeric", r_y="numeric", r_z="numeric", p="numeric"),
##'     kernel_file = kernel_file,
##'     interface_file = interface_file
##' )
##'
##'# a sample taken from Franke function 1
##'xi <-
##'c(0.11033510020934045, 0.53979828581213951, 0.5712338974699378,
##'0.61895154695957899, 0.71485369349829853, 0.1233005786780268,
##'0.3110496187582612, 0.945739162620157, 0.50002509239129722, 0.13523049908690155,
##'0.86925782053731382, 0.20504961209371686, 0.92504589096643031,
##'0.88675359822809696, 0.13629582524299622, 0.78534944215789437,
##'0.45330341416411102, 0.13574241939932108, 0.88522103684954345,
##'0.33671354013495147, 0.31927411514334381, 0.40378281474113464,
##'0.47907730704173446, 0.36790182022377849, 0.46569056762382388,
##'0.049892152892425656, 0.18735671159811318, 0.98265941371209919,
##'0.32827406958676875, 0.1709963905159384, 0.48825489450246096,
##'0.018687411677092314, 0.33948508370667696, 0.029663375578820705,
##'0.86722866306081414, 0.73170759971253574, 0.31526079680770636,
##'0.38645401177927852, 0.33244599052704871, 0.089777971152216196,
##'0.75705560250207782, 0.60296849720180035, 0.14539997256360948,
##'0.032517483457922935, 0.48376814159564674, 0.44456952787004411,
##'0.060385589953511953, 0.32750602206215262, 0.87842904729768634,
##'0.93060488626360893, 0.39217845699749887, 0.15884677483700216,
##'0.31994760106317699, 0.30696562025696039, 0.10781125444918871,
##'0.97933430341072381, 0.49690342810936272, 0.093074671924114227,
##'0.21177365817129612, 0.93050074623897672, 0.2968464067671448,
##'0.65321824885904789, 0.90107047790661454, 0.9907957932446152)
##'yi <-
##'c(0.43033322133123875, 0.39377692225389183, 0.14190889545716345,
##'0.27980669634416699, 0.56482222257182002, 0.93513950542546809,
##'0.35840014507994056, 0.84200718090869486, 0.72240921435877681,
##'0.75073598930612206, 0.92398845218122005, 0.0023781068157404661,
##'0.16042991494759917, 0.39927295129746199, 0.6753195773344487,
##'0.48037201631814241, 0.53382878075353801, 0.31695015728473663,
##'0.81475759018212557, 0.29221952124498785, 0.4091320913285017,
##'0.090918307658284903, 0.79859663802199066, 0.35978524968959391,
##'0.040487576741725206, 0.041086339857429266, 0.95443423837423325,
##'0.37334124487824738, 0.80641966755501926, 0.91005900898016989,
##'0.44007621286436915, 0.57633650302886963, 0.073667795164510608,
##'0.16462739440612495, 0.73989077587611973, 0.475711012724787,
##'0.68552095326595008, 0.95151494280435145, 0.49746448756195605,
##'0.47050062660127878, 0.56019195006228983, 0.65251012053340673,
##'0.27957349875941873, 0.97990758949890733, 0.64386410801671445,
##'0.58257843577302992, 0.61587102594785392, 0.9251402944792062,
##'0.39002289529889822, 0.2879196850117296, 0.090735964709892869,
##'0.32203390402719378, 0.75827011256478727, 0.10441292962059379,
##'0.71027785260230303, 0.96647738362662494, 0.20149122620932758,
##'0.10848865448497236, 0.055402178782969713, 0.8297235150821507,
##'0.5811977565754205, 0.47009237529709935, 0.36501412000507116,
##'0.28012462728656828)
##'fi <-
##'c(0.66703396196349263, 0.43745237092621297, 0.43284780743091933,
##'0.53063044551192828, 0.28856563372859201, 0.26711209832820537,
##'0.81121194451508127, 0.051691985701181477, 0.075441837499400796,
##'0.31451194059983117, 0.060682217438670458, 0.85427783228748577,
##'0.2755300648922186, 0.45139403218840418, 0.34406664461529252,
##'0.43932595848570688, 0.30817677521819103, 0.99892905247704966,
##'0.066794119694278106, 0.90471519567979464, 0.65751613888217064,
##'0.68373491952429688, 0.011999690860712148, 0.68502839979600239,
##'0.50547546184255721, 0.83807562521845869, 0.24803645254783765,
##'0.27400864890267046, 0.17665000067307329, 0.26222882426722999,
##'0.39330754052270583, 0.41846984284980998, 0.81975076898486043,
##'0.89729584969335685, 0.086623044633624774, 0.45545899532067197,
##'0.25383711059134573, 0.1782270067941199, 0.44485020031144856,
##'0.56659955106947513, 0.29295881670811807, 0.19020457405083468,
##'1.0960583671206787, 0.27152846500620853, 0.18795894193077431,
##'0.26686848855535034, 0.39050233350379981, 0.20339455062701103,
##'0.476343113355639, 0.38596180365908705, 0.71336249860194978,
##'1.015549028195075, 0.19902542880986107, 0.95428911733407207,
##'0.33544138932029749, 0.039896124805332028, 0.53974935190329465,
##'0.98625723892893857, 0.96952564118935636, 0.055630228560187574,
##'0.35460776764178753, 0.4243117639766259, 0.45000821385187068,
##'0.25924060651283404)
##'
##'x=seq(0,1,by=0.001)
##'nx=length(x)
##'y=seq(0,1,by=0.001)
##'ny=length(y)
##'xm<- c(matrix(rep(x,ny),nrow=nx,ncol=ny,byrow=FALSE))
##'ym<- c(matrix(rep(y,nx),nrow=nx,ncol=ny,byrow=TRUE))
##'
##'res = idw_gpu(xm,ym,xi,yi,fi,1.0)
##'res = matrix(res,nx,ny)
##'
##'image(x,y,res)
##' }
##' }
##' @export
inlineCL <- function(signature, kernel_file, interface_file, debug = FALSE, math_lib = TRUE, force_float = FALSE, ...) {

    ## We wake up the backend so that the real hardware information is available
    tryCatch({
        OpenCLeaR::EnsureOpenclInitialized()
    }, error = function(e) {
        tryCatch({ OpenCLeaR::runifOCL(1) }, error = function(err) {})
    })

    ## =========================================================================
    ## switch between local kernel and kernel in library install path (*.cl)
    ## =========================================================================
    is_local_kernel <- startsWith(kernel_file, "./") || startsWith(kernel_file, ".\\")
    if (is_local_kernel) {
        if (file.exists(kernel_file)) {
            kernel_path_final <- kernel_file
        } else {
            stop(paste0(" [OpenCLeaR] Explicitly requested local kernel file not found: ", kernel_file))
        }
    } else {
        package_kernel <- system.file("kernel", kernel_file, package = "OpenCLeaR")
        if (package_kernel != "" && file.exists(package_kernel)) {
            kernel_path_final <- package_kernel
        } else {
            stop(paste0(" [OpenCLeaR] Kernel file not found in package repository: ", kernel_file))
        }
    }
    cl_source <- paste(readLines(kernel_path_final, warn = FALSE), collapse = "\n")

    ## =========================================================================
    ## switch between local interface and interface in library install path (*.cpp)
    ## =========================================================================
    if (startsWith(interface_file, "./") || startsWith(interface_file, ".\\")) {
        if (file.exists(interface_file)) {
            interface_path_final <- interface_file
        } else {
            stop(paste0(" [OpenCLeaR] Explicitly requested local interface file not found: ", interface_file))
        }
    } else {
        package_interface <- system.file("interface", interface_file, package = "OpenCLeaR")
        if (package_interface != "" && file.exists(package_interface)) {
            interface_path_final <- package_interface
        } else {
            stop(paste0(" [OpenCLeaR] Interface file not found in package repository: ", interface_file))
        }
    }
    cpp_source <- paste(readLines(interface_path_final, warn = FALSE), collapse = "\n")
    ## =========================================================================
    ## FP32 / FP64 switch
    ## =========================================================================
    device_info <- OpenCLeaR::GetActiveDeviceInfo()
    is_fp64 <- FALSE
    ## Only when Float is NOT enforced we query the hardware for Double
    if (!isTRUE(force_float)) {
        if (isTRUE(getOption("OpenCLeaR.has_fp64"))) {
            is_fp64 <- TRUE
        }
    }
    ## Dynamic plugin selection based on the final FP64 state
    if (is_fp64) {
        chosen_plugin <- "OpenCLeaRDouble"
    } else {
        chosen_plugin <- "OpenCLeaRFloat"
    }
    ## =========================================================================
    ## mathematical library injection (unified syntax: local vs. package repo)
    ## =========================================================================
    if (is.character(math_lib)) {
        is_local_math <- startsWith(math_lib, "./") || startsWith(math_lib, ".\\")
        if (is_local_math) {
            ## use a locally stored math library
            if (file.exists(math_lib)) {
                abs_math_path <- normalizePath(math_lib, winslash = "/")
                math_lib_injection <- paste0(
                    "    device->set_math_library_path(\"", abs_math_path, "\");\n"
                )
            } else {
                stop(paste0(" [OpenCLeaR] Specified local math library not found: ", math_lib))
            }
        } else {
            ## use a math library from central package storage
            math_lib_injection <- paste0(
                "    Rcpp::Function sys_file(\"system.file\");\n",
                "    std::string pkg_kernel_dir = Rcpp::as<std::string>(sys_file(\"kernel\", Rcpp::Named(\"package\") = \"OpenCLeaR\"));\n",
                "    std::string math_lib_file = pkg_kernel_dir + \"/\" +\"", math_lib,"\";\n",
                "    if (!std::ifstream(math_lib_file).good()) {\n",
                "        Rcpp::stop(\" [OpenCLeaR] Math library not found in package repository: \" + math_lib_file);\n",
                "    }\n",
                "    device->set_math_library_path(math_lib_file);\n"
            )
        }
    } else if (isTRUE(math_lib)) {
        ## default: use libkernel.cl from installed package:
        math_lib_injection <- paste0(
            "    Rcpp::Function sys_file(\"system.file\");\n",
            "    std::string pkg_kernel_dir = Rcpp::as<std::string>(sys_file(\"kernel\", Rcpp::Named(\"package\") = \"OpenCLeaR\"));\n",
            "    std::string math_lib_file = pkg_kernel_dir + \"/libkernel.cl\";\n",
            "    device->set_math_library_path(math_lib_file);\n"
        )
    } else {
        ## no math lib:
        math_lib_injection <- "    device->set_math_library_path(\"\");\n"
    }

    ## DIE ABSOLUTE REIHENFOLGEN-ABSICHERUNG:
    full_cl_code <- paste0(
        "    Rcpp::Function system_file(\"system.file\");\n",
        "    std::string compiler_dir = Rcpp::as<std::string>(system_file(\"bin\", Rcpp::Named(\"package\") = \"OpenCLeaR\"));\n",
        ## Set the kernel path dynamically depending on local or global kernel.
        if (is_local_kernel) {
            "    std::string kernel_dir  = \".\";\n"
        } else {
            "    std::string kernel_dir  = Rcpp::as<std::string>(system_file(\"kernel\", Rcpp::Named(\"package\") = \"OpenCLeaR\"));\n"
        },
        ## STEP 1: Commit path to device object BEFORE the JIT compiler pipeline starts!
        "    device->set_kernel_path(kernel_dir);\n",
        "    device->set_kernel_file(\"", kernel_file, "\");\n",
        "    device->set_kernel_name(\"", kernel_file, "\");\n",
        "    device->initialize_binary_cache_path();\n",
        if (isTRUE(force_float)) {
            "    device->info.is_fp64_capable = 0;\n"
        } else {
            ""
        },
        math_lib_injection,
        if (isTRUE(debug)) {
            paste0(
                "    std::ofstream debug_file(\"debug_kernel.cl\");\n",
                "    debug_file << device->get_compiled_code();\n",
                "    debug_file.close();\n"
            )
        } else {
            "\n"
        },
        "    std::string compiler_folder = compiler_dir;\n",
        "    device->set_compiler_path(compiler_folder);\n",
        ## STEP 2: Only now call the compiler
        "    device->load_or_build_kernel();\n"
    )
    ## =========================================================================
    ## tunnel the device address into to shared object: No DLL locks on JIT run
    ## =========================================================================
    extended_signature <- c(signature, "Device_Address" = "numeric")
    modified_cpp_body <- paste0(
        "    #include <fstream>\n",
        "    using namespace backend;\n",
        "    uintptr_t addr = (uintptr_t)Rcpp::as<double>(Device_Address);\n",
        "    if(addr == 0) { Rcpp::stop(\" Critical error: Device_Address is NULL!\"); }\n",
        "    Device* device = reinterpret_cast<Device*>(addr);\n",
        ## switch between FP32/FP63 mode in interface code
        "    #if FP64_MODE == 1\n",
        "        typedef double real;\n",
        "    #else\n",
        "        typedef float real;\n",
        "    #endif\n",
        full_cl_code,
        cpp_source
    )
    executable_r_func <- inline::cxxfunction(
                                     sig     = extended_signature,
                                     body    = modified_cpp_body,
                                     plugin  = chosen_plugin,
                                     package = "OpenCLeaR",
                                     ...
                                 )
    ## This clever switch gets the address under Windows directly from the XPtr
    final_wrapper <- function(...) {
        if (.Platform$OS.type == "windows") {
            ## Gets the C++ transient pointer from the R environment
            ocl_env <- getFromNamespace(".OpenCLeaR_Env", "OpenCLeaR")
            if (is.null(ocl_env$active_device_ptr)) {
                stop(" [OpenCLeaR] No active Windows hardware pointer found in memory!")
            }
            ## The numeric cast pulls the raw 64-bit address from the Rcpp::XPtr
            ## We get the double carrying the address here
            dev_addr <- OpenCLeaR::GetActiveDeviceInfo()$Device_Address
        } else {
            ## Linux/Mac uses the singleton state of the backend as usual
            dev_addr <- OpenCLeaR::GetActiveDeviceInfo()$Device_Address
        }
        executable_r_func(..., Device_Address = dev_addr)
    }
    return(final_wrapper)
}
##' Creates a self-adapting GPGPU-interface function.
##' @param signature call signature
##' @param kernel_file OpenCL kernel file name,
##' if it starts with "./" it will
##' be searched in local directory, otherwise in subdirectory "kernel"
##' of installed library.
##' @param interface_file filename where the Rcpp body is stored.
##' if it starts wit "./" it will
##' be searched in local directory, otherwise in subdirectory "interface"
##' of installed library.
##' @param math_lib Logical. If TRUE, inject the mathematical kernel library.
##' @param force_float Logical. If TRUE, forces single-precision calculations.
##' @param verbose Logical. Enable verbose compiler outputs.
##' @param debug Logical. Export raw compiled source string for debugging.
##' @param cache Logical. If TRUE, cache the compiled function locally.
##' @details
##' This function uses the inline mechanism in \code{inlineCL} to create a R function
##' which adapts on the fly to your activated OpenCL device and recompiles the both the kernel and
##' the interface code to match its floating point architecture.
##' @examples
##' if(EnsureOpenclInitialized()){
##' kernel_file <- "idw_kernel.cl"
##' interface_file <- "idw_rcpp.cpp"
##'
##' idw_gpu <- oclFunction(
##'   signature = signature(r_x0="numeric", r_y0="numeric",
##'                         r_x="numeric", r_y="numeric",
##'                         r_z="numeric", p="numeric"),
##'   kernel_file           = kernel_file,
##'   interface_file        = interface_file
##' )
##'# a sample taken from Franke function 1
##'xi <-
##'c(0.11033510020934045, 0.53979828581213951, 0.5712338974699378,
##'0.61895154695957899, 0.71485369349829853, 0.1233005786780268,
##'0.3110496187582612, 0.945739162620157, 0.50002509239129722, 0.13523049908690155,
##'0.86925782053731382, 0.20504961209371686, 0.92504589096643031,
##'0.88675359822809696, 0.13629582524299622, 0.78534944215789437,
##'0.45330341416411102, 0.13574241939932108, 0.88522103684954345,
##'0.33671354013495147, 0.31927411514334381, 0.40378281474113464,
##'0.47907730704173446, 0.36790182022377849, 0.46569056762382388,
##'0.049892152892425656, 0.18735671159811318, 0.98265941371209919,
##'0.32827406958676875, 0.1709963905159384, 0.48825489450246096,
##'0.018687411677092314, 0.33948508370667696, 0.029663375578820705,
##'0.86722866306081414, 0.73170759971253574, 0.31526079680770636,
##'0.38645401177927852, 0.33244599052704871, 0.089777971152216196,
##'0.75705560250207782, 0.60296849720180035, 0.14539997256360948,
##'0.032517483457922935, 0.48376814159564674, 0.44456952787004411,
##'0.060385589953511953, 0.32750602206215262, 0.87842904729768634,
##'0.93060488626360893, 0.39217845699749887, 0.15884677483700216,
##'0.31994760106317699, 0.30696562025696039, 0.10781125444918871,
##'0.97933430341072381, 0.49690342810936272, 0.093074671924114227,
##'0.21177365817129612, 0.93050074623897672, 0.2968464067671448,
##'0.65321824885904789, 0.90107047790661454, 0.9907957932446152)
##'yi <-
##'c(0.43033322133123875, 0.39377692225389183, 0.14190889545716345,
##'0.27980669634416699, 0.56482222257182002, 0.93513950542546809,
##'0.35840014507994056, 0.84200718090869486, 0.72240921435877681,
##'0.75073598930612206, 0.92398845218122005, 0.0023781068157404661,
##'0.16042991494759917, 0.39927295129746199, 0.6753195773344487,
##'0.48037201631814241, 0.53382878075353801, 0.31695015728473663,
##'0.81475759018212557, 0.29221952124498785, 0.4091320913285017,
##'0.090918307658284903, 0.79859663802199066, 0.35978524968959391,
##'0.040487576741725206, 0.041086339857429266, 0.95443423837423325,
##'0.37334124487824738, 0.80641966755501926, 0.91005900898016989,
##'0.44007621286436915, 0.57633650302886963, 0.073667795164510608,
##'0.16462739440612495, 0.73989077587611973, 0.475711012724787,
##'0.68552095326595008, 0.95151494280435145, 0.49746448756195605,
##'0.47050062660127878, 0.56019195006228983, 0.65251012053340673,
##'0.27957349875941873, 0.97990758949890733, 0.64386410801671445,
##'0.58257843577302992, 0.61587102594785392, 0.9251402944792062,
##'0.39002289529889822, 0.2879196850117296, 0.090735964709892869,
##'0.32203390402719378, 0.75827011256478727, 0.10441292962059379,
##'0.71027785260230303, 0.96647738362662494, 0.20149122620932758,
##'0.10848865448497236, 0.055402178782969713, 0.8297235150821507,
##'0.5811977565754205, 0.47009237529709935, 0.36501412000507116,
##'0.28012462728656828)
##'fi <-
##'c(0.66703396196349263, 0.43745237092621297, 0.43284780743091933,
##'0.53063044551192828, 0.28856563372859201, 0.26711209832820537,
##'0.81121194451508127, 0.051691985701181477, 0.075441837499400796,
##'0.31451194059983117, 0.060682217438670458, 0.85427783228748577,
##'0.2755300648922186, 0.45139403218840418, 0.34406664461529252,
##'0.43932595848570688, 0.30817677521819103, 0.99892905247704966,
##'0.066794119694278106, 0.90471519567979464, 0.65751613888217064,
##'0.68373491952429688, 0.011999690860712148, 0.68502839979600239,
##'0.50547546184255721, 0.83807562521845869, 0.24803645254783765,
##'0.27400864890267046, 0.17665000067307329, 0.26222882426722999,
##'0.39330754052270583, 0.41846984284980998, 0.81975076898486043,
##'0.89729584969335685, 0.086623044633624774, 0.45545899532067197,
##'0.25383711059134573, 0.1782270067941199, 0.44485020031144856,
##'0.56659955106947513, 0.29295881670811807, 0.19020457405083468,
##'1.0960583671206787, 0.27152846500620853, 0.18795894193077431,
##'0.26686848855535034, 0.39050233350379981, 0.20339455062701103,
##'0.476343113355639, 0.38596180365908705, 0.71336249860194978,
##'1.015549028195075, 0.19902542880986107, 0.95428911733407207,
##'0.33544138932029749, 0.039896124805332028, 0.53974935190329465,
##'0.98625723892893857, 0.96952564118935636, 0.055630228560187574,
##'0.35460776764178753, 0.4243117639766259, 0.45000821385187068,
##'0.25924060651283404)
##'
##'x=seq(0,1,by=0.001)
##'nx=length(x)
##'y=seq(0,1,by=0.001)
##'ny=length(y)
##'xm<- c(matrix(rep(x,ny),nrow=nx,ncol=ny,byrow=FALSE))
##'ym<- c(matrix(rep(y,nx),nrow=nx,ncol=ny,byrow=TRUE))
##'
##'res = idw_gpu(xm,ym,xi,yi,fi,1.0)
##'res = matrix(res,nx,ny)
##'
##'image(x,y,res)
##'}
##'
##' @export
oclFunction <- function(signature, kernel_file, interface_file, math_lib = TRUE, force_float = FALSE, verbose = FALSE, debug = FALSE, cache = TRUE) {
    ## handle cached version
    kernel_base_name <- tools::file_path_sans_ext(basename(kernel_file))
    
    ## Hide local state via lexical scoping for fast hot-path checks
    compiled_func    <- NULL
    last_device_id   <- NULL
    last_fp64_state  <- NULL
    last_force_float <- NULL
    last_cache_key   <- NULL

    ## The final wrapper function
    function(...) {
        ## Get system and hardware info
        sys_info <- Sys.info()
        platform_prefix <- paste0(tolower(sys_info[["sysname"]]), "_", tolower(sys_info[["machine"]]))
        dev_info <- OpenCLeaR::GetActiveDeviceInfo()

        raw_vendor <- dev_info$Vendor
        raw_device <- dev_info$Name
        if (is.null(raw_vendor) || length(raw_vendor) == 0 || raw_vendor == "") raw_vendor <- "unbound"
        if (is.null(raw_device) || length(raw_device) == 0 || raw_device == "") raw_device <- "device"

        clean_vendor <- gsub("[^a-zA-Z0-9]", "_", tolower(raw_vendor))
        clean_device <- gsub("[^a-zA-Z0-9]", "_", tolower(raw_device))
        clean_vendor <- gsub("_+", "_", clean_vendor)
        clean_device <- gsub("_+", "_", clean_device)

        fp64_suffix <- if(isTRUE(getOption("OpenCLeaR.has_fp64"))) "_fp64" else "_fp32"
        prec_suffix <- if (force_float) "_force_float" else "_no_force_float"

        ## Unique cache key for this specific device compilation
        cache_key <- paste0(".",
                            kernel_base_name, "_",
                            platform_prefix, "_",
                            clean_vendor, "_",
                            clean_device, "_dev",
                            dev_info$Index,
                            fp64_suffix,
                            prec_suffix,
                            "_ocl_internal")
        
        cache_env <- asNamespace("OpenCLeaR")$.OpenCLeaR_Env

        ## Check if a device or mode change happened
        current_id   <- dev_info$Index
        current_fp64 <- isTRUE(getOption("OpenCLeaR.has_fp64"))
        if (isTRUE(force_float)) current_fp64 <- FALSE

        need_state_update <- is.null(compiled_func) ||
            (cache_key != last_cache_key) ||
            (current_id != last_device_id) ||
            (current_fp64 != last_fp64_state) ||
            (force_float != last_force_float)

        if (need_state_update) {
            ## Check whether we already have something in cache for this hardware
            if (cache && exists(cache_key, envir = cache_env, inherits = FALSE)) {
                global_func <- get(cache_key, envir = cache_env)
                if (is.function(global_func)) {
                    compiled_func <<- global_func
                    last_cache_key   <<- cache_key
                    last_device_id   <<- current_id
                    last_fp64_state  <<- current_fp64
                    last_force_float <<- force_float
                    return(compiled_func(...))
                }
            }

            ## If absolutely nothing exists in the cache -> (Re)Compile
            cat(" [OpenCLeaR Runtime] hardware change or float/double mode change detected! recompile ...\n")
            compiled_func <<- OpenCLeaR::inlineCL(
                                             signature      = signature,
                                             kernel_file    = kernel_file,
                                             interface_file = interface_file,
                                             math_lib       = math_lib,
                                             force_float    = force_float,
                                             verbose        = verbose,
                                             debug          = debug
                                         )
            
            last_cache_key   <<- cache_key
            last_device_id   <<- current_id
            last_fp64_state  <<- current_fp64
            last_force_float <<- force_float

            ## Save to global cache for future switches
            if (cache) {
                assign(cache_key, compiled_func, envir = cache_env)
            }
        }

        ## Execute with the real arguments
        return(compiled_func(...))
    }
}
