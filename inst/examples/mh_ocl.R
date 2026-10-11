library(inline)
library(OpenCLeaR)
library(ggplot2)
library(gridExtra)

cat("⏳ Kompiliere GPGPU-Laufzeit-Objekt via oclFunction...\n")

parallel_MH_sampler <- oclFunction(
    signature = signature(
        n_samples   = "integer",
        n_chains    = "integer",
        data_vector = "numeric",
        mu_init     = "numeric",
        sigma_init  = "numeric"
    ),
    kernel_file     = "mh_sampler.cl",
    interface_file  = "mh_sampler.cpp",
    force_float = T
)

