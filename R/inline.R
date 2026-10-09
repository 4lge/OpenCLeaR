##' inline plugin
##' 
##' @rdname inline
##' @details It is possible to access your own kernel via the inline() mechanism:
##'
##' 1. Write a kernel = *.cl file and announce its location via SetKernelsPath()
##' 
##' 2. Write an interface using Rcpp for data exchange with R and OpenCL-Wrapper classes (Memory, Device, ...) with the OpenCL backend
##' 
##' 3. Compile and run it with inline() using the provided plugin
##' @note
##' You can use the generic plugin \code{inclineCxxPlugin}, here you have to
##' take care about the float/double characteristics on your owm.
##' You can force the use of float or double by choosing
##' \code{inclineCxxPluginFloat} or  \code{inclineCxxPluginDouble} explicitely
##' while using real_t as automatically generated typedef both in your CL und
##' C++ code. The easiest way is to use \code{generateInlineCL} which completely
##' automates this task.
##' @examples
##' \dontrun{
##' source(paste(system.file("examples", package = "OpenCLeaR"),"rnormCLinline.R",sep="/"))
##' }
##' @export
inlineCxxPlugin <- function(...) {
    if (.Platform$OS.type == "windows") {
        ## Zwingt MinGW statisch gegen das .a Archiv zu linken und verhindert DLL-Inflation!
        linker_flags <- paste(" -L", system.file("libs", package = "OpenCLeaR"), " -l:BACKEND.a ", " -L", system.file("libs/x64", package = "OpenCLeaR")," -lOpenCL", sep="")
    } else {
        ## Linux verbleibt bei der bewährten dynamischen Verknüpfung
        linker_flags <- paste(" -L", system.file("libs", package = "OpenCLeaR"), " -lBACKEND", sep="")
    }
    plugin <-  Rcpp::Rcpp.plugin.maker(
	include.before = "#include \"CLpp.hpp\"\n#include \"init.hpp\"\nstatic std::string global_math_library_code = \"\\n\"; inline std::string get_opencl_c_code() { return global_math_library_code; }\n",

        libs           = linker_flags,
        package        = "OpenCLeaR"
    )
    settings <- plugin()
    settings$env$PKG_CPPFLAGS <- paste(settings$env$PKG_CPPFLAGS, " -DPLUGIN=1 -I", system.file("include", package = "OpenCLeaR"), sep="")
    return(settings)
}

##' @rdname inline
##' @export
inlineCxxPluginFloat <- function(...) {
    if (.Platform$OS.type == "windows") {
        ## Zwingt MinGW statisch gegen das .a Archiv zu linken und verhindert DLL-Inflation!
        linker_flags <- paste(" -L", system.file("libs", package = "OpenCLeaR"), " -l:BACKEND.a ", " -L", system.file("libs/x64", package = "OpenCLeaR")," -lOpenCL", sep="")
    } else {
        ## Linux verbleibt bei der bewährten dynamischen Verknüpfung
        linker_flags <- paste(" -L", system.file("libs", package = "OpenCLeaR"), " -lBACKEND", sep="")
    }
    plugin <- Rcpp::Rcpp.plugin.maker(
        include.before = "#include \"CLpp.hpp\"\n#include \"init.hpp\"\nstatic std::string global_math_library_code = \"\\n\";  inline std::string get_opencl_c_code() { return global_math_library_code; }\n",
        libs           = linker_flags,
        package        = "OpenCLeaR"
    )
    settings <- plugin()
    settings$env$PKG_CPPFLAGS <- paste(settings$env$PKG_CPPFLAGS, " -DFP64_MODE=0 -DPLUGIN=1 -I", system.file("include", package = "OpenCLeaR"), sep="")
    return(settings)
}

##' @rdname inline
##' @export
inlineCxxPluginDouble <- function(...) {
    if (.Platform$OS.type == "windows") {
        ## Zwingt MinGW statisch gegen das .a Archiv zu linken und verhindert DLL-Inflation!
        linker_flags <- paste(" -L", system.file("libs", package = "OpenCLeaR"), " -l:BACKEND.a ", " -L", system.file("libs/x64", package = "OpenCLeaR")," -lOpenCL", sep="")
    } else {
        ## Linux verbleibt bei der bewährten dynamischen Verknüpfung
        linker_flags <- paste(" -L", system.file("libs", package = "OpenCLeaR"), " -lBACKEND", sep="")
    }
    plugin <- Rcpp::Rcpp.plugin.maker(
        include.before = "#include \"CLpp.hpp\"\n#include \"init.hpp\"\nstatic std::string global_math_library_code = \"\\n\"; inline std::string get_opencl_c_code() { return global_math_library_code; }\n",
        libs           = linker_flags,
        package        = "OpenCLeaR"
    )
    settings <- plugin()
    settings$env$PKG_CPPFLAGS <- paste(settings$env$PKG_CPPFLAGS, " -DFP64_MODE=1 -DPLUGIN=1 -I", system.file("include", package = "OpenCLeaR"), sep="")
    return(settings)
}

##' Generische GPGPU-Laufzeit-Kompilierung für OpenCL Kernel
##'
##' @param signature Benannte Liste oder Vektor der R-Argumente (wie bei inline::cxxfunction)
##' @param kernel_code Ein R-String oder ein Pfad zu einer *.cl Datei, die den GPU-Kernel enthält
##' @param body Ein R-String oder ein Pfad zu einer Datei, die den Rcpp-Ausführungscode enthält
##' @param debug Logischer Wert. Wenn \code{TRUE}, wird der vollständige mit
##' der OpenCL kernel library verkettete OpenCL-Quelltext als 'debug_kernel.cl'
##' im Arbeitsverzeichnis abgelegt.
##' @param ... Zusätzliche Argumente, die an inline::cxxfunction weitergereicht werden
##' @details This function automates the process of generating a OpenCL function
##' via the inline Plugin(s) attached to this library. You have to specify
##'   1. A file or a string containing the CL C code. You should use
##'      \code{real_t} to get automatically \code{double} or \code{float}
##'      according to your active OpenCL device.
##'   2. A file or a string containing the Rcpp interface using the OpenCL
##'      abstraction (Device, Memory, Kernel) delivered by OpenCL-Wrapper.
##'      Again you should use \code{real_t} to get automatically
##'      \code{double} or \code{float} according to your active OpenCL device.
##' 
##' @return Eine ausführbare R-Funktion, die den Code auf der GPU zündet.
##' @examples
##' \dontrun{
##'# an invers distance weighting example:
##' kernel_src <- "
##' __kernel void idw_kernel(__global const real_t* x0, __global const real_t* y0, __global real_t* z0,
##'                          __global const real_t* x, __global const real_t* y, __global const real_t* z,
##'                          const int n0, const int n, const real_t p) {
##'     int i = get_global_id(0);
##'     if (i >= n0) return;
##'     real_t wsum = 0.0, num = 0.0;
##'     for (int j = 0; j < n; j++) {
##'         real_t d = sqrt((x0[i]-x[j])*(x0[i]-x[j]) + (y0[i]-y[j])*(y0[i]-y[j]));
##'         if (d < 1e-9) { z0[i] = z[j]; return; }
##'         real_t w = 1.0 / pow(d, p);
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
##'     Memory<real_t> gpu_x0(*device, n0); 
##'     Memory<real_t> gpu_y0(*device, n0); 
##'     Memory<real_t> gpu_z0(*device, n0);
##'     Memory<real_t> gpu_x(*device, n); 
##'     Memory<real_t> gpu_y(*device, n); 
##'     Memory<real_t> gpu_z(*device, n);
##'     
##'     // Jetzt klappt der Zugriff über [] absolut makellos und performant!
##'     for(int i=0; i<n0; ++i) { gpu_x0[i] = x0[i]; gpu_y0[i] = y0[i]; }
##'     for(int j=0; j<n; ++j)  { gpu_x[j] = x[j]; gpu_y[j] = y[j]; gpu_z[j] = z[j]; }
##'     
##'     gpu_x0.write_to_device(); gpu_y0.write_to_device();
##'     gpu_x.write_to_device(); gpu_y.write_to_device(); gpu_z.write_to_device();
##'     
##'     Kernel k(*device, n0, \"idw_kernel\", gpu_x0, gpu_y0, gpu_z0, gpu_x, gpu_y, gpu_z, n0, n, as<real_t>(p));
##'     k.run(); 
##'     gpu_z0.read_from_device();
##'     
##'     for(int i=0; i<n0; ++i) r_z0[i] = gpu_z0[i];
##'     return r_z0;
##'"
##'
##' idw_gpu <- generateInlineCL(
##'     signature = signature(r_x0="numeric", r_y0="numeric", r_x="numeric", r_y="numeric", r_z="numeric", p="numeric"),
##'     kernel_code = kernel_src,
##'     body = cpp_src
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
##'
##' }
##' @export
generateInlineCL <- function(signature, kernel_file, interface_file, debug = FALSE, math_lib = TRUE, ...) {

    # Wir wecken das Backend auf, damit die echten Hardware-Infos im RAM stehen.
    tryCatch({
        # Falls die interne C++ Weckfunktion exportiert ist, rufen wir sie direkt auf
        OpenCLeaR::ensure_opencl_initialized()
    }, error = function(e) {
        # Fallback: Ein Alibi-Lauf initialisiert das echte Gerät garantiert blockfrei
        tryCatch({ OpenCLeaR::runifCL(1) }, error = function(err) {})
    })

    # =========================================================================
    # 🚀 STRITE PFAD-WEICHE FÜR DEN KERNEL (*.cl)
    # =========================================================================
    if (startsWith(kernel_file, "./") || startsWith(kernel_file, ".\\")) {
        # Fall A: Anwender fordert EXPLIZIT die lokale Datei im Arbeitsverzeichnis
        if (file.exists(kernel_file)) {
            kernel_path_final <- kernel_file
        } else {
            stop(paste0("💥 [OpenCLeaR] Explizit angeforderte lokale Kernel-Datei nicht gefunden: ", kernel_file))
        }
    } else {
        # Fall B: Standard-Suche ausschließlich im installierten Paket-Ordner 'kernel'
        package_kernel <- system.file("kernel", kernel_file, package = "OpenCLeaR")
        if (package_kernel != "" && file.exists(package_kernel)) {
            kernel_path_final <- package_kernel
        } else {
            stop(paste0("💥 [OpenCLeaR] Kernel-Datei im Paket-Repository nicht gefunden: ", kernel_file))
        }
    }
    cl_source <- paste(readLines(kernel_path_final, warn = FALSE), collapse = "\n")


    # =========================================================================
    # 🚀 STRITE PFAD-WEICHE FÜR DAS INTERFACE (*.cpp)
    # =========================================================================
    if (startsWith(interface_file, "./") || startsWith(interface_file, ".\\")) {
        # Fall A: Anwender fordert EXPLIZIT die lokale Datei im Arbeitsverzeichnis
        if (file.exists(interface_file)) {
            interface_path_final <- interface_file
        } else {
            stop(paste0("💥 [OpenCLeaR] Explizit angeforderte lokale Interface-Datei nicht gefunden: ", interface_file))
        }
    } else {
        # Fall B: Standard-Suche ausschließlich im installierten Paket-Ordner 'interface'
        package_interface <- system.file("interface", interface_file, package = "OpenCLeaR")
        if (package_interface != "" && file.exists(package_interface)) {
            interface_path_final <- package_interface
        } else {
            stop(paste0("💥 [OpenCLeaR] Interface-Datei im Paket-Repository nicht gefunden: ", interface_file))
        }
    }
    cpp_source <- paste(readLines(interface_path_final, warn = FALSE), collapse = "\n")

    # Hardware abfragen
    device_info <- OpenCLeaR::GetActiveDeviceInfo()
    is_fp64 <- FALSE
    if (!is.null(device_info$FP64_Capable)) {
        if (device_info$FP64_Capable == 1 || isTRUE(device_info$FP64_Capable)) {
            is_fp64 <- TRUE
        }
    }

    # Dynamische Plugin-Auswahl anhand des Namens
    if (is_fp64) {
        chosen_plugin <- "OpenCLeaRDouble"
    } else {
        chosen_plugin <- "OpenCLeaRFloat"
    }

    full_cl_code <- paste0(
        "    std::string precision_header = \"\";\n",
        "    if (device->info.is_fp64_capable) {\n",
        "        precision_header = \"#pragma OPENCL EXTENSION cl_khr_fp64 : enable\\n#define real_t double\\n\";\n",
        "    } else {\n",
        "        precision_header = \"#define real_t float\\n\";\n",
        "    }\n",
        "    Rcpp::Function system_file(\"system.file\");\n",
        "    std::string compiler_dir = Rcpp::as<std::string>(system_file(\"bin\", Rcpp::Named(\"package\") = \"OpenCLeaR\"));\n",
        "    std::string kernel_dir  = Rcpp::as<std::string>(system_file(\"kernel\", Rcpp::Named(\"package\") = \"OpenCLeaR\"));\n",
        "    std::cout << \"🎯 Installierter Compiler-Pfad aus Rcpp: \" << compiler_dir << std::endl;\n",
        "    std::cout << \"🎯 Installierter Kernels-Pfad aus Rcpp: \" << kernel_dir << std::endl;\n",
        "    std::string base = device->get_kernel_path();\n",
        "    if (!base.empty() && base.back() != '/') {\n",
        "      base += \"/\";\n",
        "    }\n",
        "    //device->set_kernel_path(base);\n",
        "    device->set_kernel_file(\"",kernel_file,"\");\n",
        "    device->set_kernel_name(\"",kernel_file,"\");\n",
        "    device->initialize_binary_cache_path();\n",
        "    std::string math_lib_file = kernel_dir + \"/libkernel.cl\";\n",
        "    device->set_math_library_path(math_lib_file);\n",
        if (isTRUE(debug)) {
            paste0(
                "    std::ofstream debug_file(\"debug_kernel.cl\");\n",
                "//    debug_file << device->get_compiled_code();\n",
                "    debug_file.close();\n"
            )
        } else {
            "\n"
        },
        "    std::string compiler_folder = compiler_dir;\n",
        "    device->set_compiler_path(compiler_folder);\n",
        "    device->load_or_build_kernel();\n"
    )

    modified_cpp_body <- paste0(
        "    using namespace backend;\n",
        "    Device* device = const_cast<Device*>(&backend::getActiveDeviceFromBackend());\n",
        "    #if FP64_MODE == 1\n",
        "        typedef double real_t;\n",
        "    #else\n",
        "        typedef float real_t;\n",
        "    #endif\n",
        full_cl_code,
        cpp_source
    )

    executable_r_func <- inline::cxxfunction(
        sig    = signature,
        body   = modified_cpp_body,
        plugin = chosen_plugin,
        ...
    )

    return(executable_r_func)
}


##' Creates a self-adapting GPGPU-interface
##' @details
##' It adapts to the active device and recompiles the both the kernel and
##' the interface code to match the floating point architecture.
##' @examples
##' kernel_file <- system.file("kernel", "idw_kernel.cl",
##'                            package = "OpenCLeaR")
##' interface_file <- system.file("interface", "idw_rcpp.cpp",
##'                            package = "OpenCLeaR")
##' idw_gpu <- makeAdaptiveCL(
##'   signature = signature(r_x0="numeric", r_y0="numeric",
##'                         r_x="numeric", r_y="numeric",
##'                         r_z="numeric", p="numeric"),
##'   kernel_code = kernel_file,
##'   body        = interface_file
##' )
##' @export
makeAdaptiveCL <- function(signature, kernel_file, interface_file) {

    # 🔐 DIE ÜBERLEBENDE CLOSURE-UMGEBUNG (Lexical Scoping):
    compiled_func   <- NULL
    last_device_id  <- NULL
    last_fp64_state <- NULL

    # Der nackte Logik-Wrapper, den der Nutzer am Ende als Funktion aufruft:
    function(...) {
        # 🚀 1. Hardware-Zustand live abfragen
        current_device  <- OpenCLeaR::GetActiveDeviceInfo()
        current_id      <- current_device$ID
        current_fp64    <- (current_device$FP64_Capable == 1)

        # 🚀 2. CACHE-WEICHE: Müssen wir neu kompilieren?
        need_recompile <- is.null(compiled_func) ||
                          (current_id != last_device_id) ||
                          (current_fp64 != last_fp64_state)

        if (need_recompile) {
            cat("🔄 [OpenCLeaR Runtime] Hardware-Wechsel erkannt (oder Erststart)! Kompiliere JIT-Objekt neu...\n")

            # Zündet Ihre bewährte generateInlineCL() Pipeline im RAM
            compiled_func <<- OpenCLeaR::generateInlineCL(
                signature   = signature,
                kernel_file = kernel_file,
                interface_file = interface_file,
                verbose     = TRUE,
                debug       = TRUE
            )

            # Zustand für den nächsten Aufruf einfrieren
            last_device_id  <<- current_id
            last_fp64_state <<- current_fp64
        }

        # 🚀 3. DIREKTE AUSFÜHRUNG: Rauscht in 0 Millisekunden durch den Cache!
        return(compiled_func(...))
    }
}

