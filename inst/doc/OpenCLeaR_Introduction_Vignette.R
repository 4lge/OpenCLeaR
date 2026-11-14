## ----setup, include=FALSE-----------------------------------------------------
knitr::opts_chunk$set(echo = TRUE, warning = FALSE, message = FALSE)
library(OpenCLeaR)


## ----create_math_library------------------------------------------------------
libkernel_src <- '
static inline real compute_sigmoid(real x) {
    return (real)1.0f / ((real)1.0f + exp(-x));
}
'
writeLines(libkernel_src, "./libkernel.cl")


## ----create_vector_kernel-----------------------------------------------------
vector_kernel_src <- '
__kernel void sigmoid_add_kernel(__global const real* a,
                                 __global const real* b,
                                 __global real* c,
                                 const int n) {
    int id = get_global_id(0);
    if (id < n) {
        real sum = a[id] + b[id];
        c[id] = compute_sigmoid(sum);
    }
}
'
writeLines(vector_kernel_src, "./sigmoid_add_kernel.cl")


## ----eval = FALSE-------------------------------------------------------------
# signature(a = "numeric", b = "numeric")


## ----create_vector_rcpp_1, eval = FALSE---------------------------------------
# vector_interface_src <- '
# NumericVector r_a(a);
# NumericVector r_b(b);


## ----create_vector_rcpp_2, eval = FALSE---------------------------------------
# int n = r_a.size();
# NumericVector r_c(n);


## ----create_vector_rcpp_3, eval = FALSE---------------------------------------
# Memory<real> gpu_a(*device, n);
# Memory<real> gpu_b(*device, n);
# Memory<real> gpu_c(*device, n);


## ----create_vector_rcpp_4, eval = FALSE---------------------------------------
# for(int i = 0; i < n; ++i) {
#     gpu_a[i] = r_a[i];
#     gpu_b[i] = r_b[i];
# }


## ----create_vector_rcpp_5, eval = FALSE---------------------------------------
# gpu_a.write_to_device();
# gpu_b.write_to_device();


## ----create_vector_rcpp_6, eval = FALSE---------------------------------------
# Kernel k(*device, (ulong)n, "sigmoid_add_kernel", gpu_a, gpu_b, gpu_c, n);


## ----create_vector_rcpp_7, eval = FALSE---------------------------------------
# k.run();


## ----create_vector_rcpp_8, eval = FALSE---------------------------------------
# gpu_c.read_from_device();
# for(int i = 0; i < n; ++i) {
#     r_c[i] = gpu_c[i];
# }
# return r_c;


## ----create_vector_rcpp-------------------------------------------------------
vector_interface_src <- '
NumericVector r_a(a);
NumericVector r_b(b);

int n = r_a.size();
NumericVector r_c(n);

Memory<real> gpu_a(*device, n);
Memory<real> gpu_b(*device, n);
Memory<real> gpu_c(*device, n);

for(int i = 0; i < n; ++i) {
    gpu_a[i] = r_a[i];
    gpu_b[i] = r_b[i];
}

gpu_a.write_to_device();
gpu_b.write_to_device();

Kernel k(*device, (ulong)n, "sigmoid_add_kernel", gpu_a, gpu_b, gpu_c, n);
k.run();

gpu_c.read_from_device();
for(int i = 0; i < n; ++i) {
    r_c[i] = gpu_c[i];
}

return r_c;
'
writeLines(vector_interface_src, "./sigmoid_add_rcpp.cpp")


## ----gpu vector add ocl function----------------------------------------------
sigmoid_vector_gpu <- (function() {
    .vector_gpu_internal <- NULL
    function(vec_x, vec_y) {
        if (is.null(.vector_gpu_internal)) {
            .vector_gpu_internal <<- OpenCLeaR::oclFunction(
                signature      = signature(a = "numeric", b = "numeric"),
                kernel_file    = "./sigmoid_add_kernel.cl",
                interface_file = "./sigmoid_add_rcpp.cpp",
                math_lib       = "./libkernel.cl"
                )
        }
        return(.vector_gpu_internal(a = vec_x, b = vec_y))
    }
})()


## ----opencl init--------------------------------------------------------------
GetDeviceList()
ActivateDevice(0)
GetActiveDeviceInfo()


## ----gpu vector add-----------------------------------------------------------
N_vec <- 5000000L
set.seed(123)
vec_a <- runif(N_vec, -3, 3)
vec_b <- runif(N_vec, -3, 3)

start_cpu_vec <- Sys.time()
res_cpu_vec <- 1 / (1 + exp(-(vec_a + vec_b)))
end_cpu_vec <- Sys.time()
time_cpu_vec <- as.numeric(difftime(end_cpu_vec, start_cpu_vec, units = "secs"))

silent_warmup_vec <- sigmoid_vector_gpu(vec_a[1:10], vec_b[1:10])

start_gpu_vec <- Sys.time()
res_gpu_vec <- sigmoid_vector_gpu(vec_a, vec_b)
end_gpu_vec <- Sys.time()
time_gpu_vec <- as.numeric(difftime(end_gpu_vec, start_gpu_vec, units = "secs"))

max_diff_vec <- max(abs(res_cpu_vec - res_gpu_vec))
cat("📊 Vector Maximum Discrepancy:", max_diff_vec, "\n")
cat("⏱️ CPU Vector Time:", round(time_cpu_vec, 4), "s\n")
cat("⏱️ GPU Vector Time:", round(time_gpu_vec, 4), "s (Speedup:", round(time_cpu_vec / time_gpu_vec, 2), "x)\n")


## ----create_forward_kernel----------------------------------------------------
nn_kernels_src <- '
__kernel void dense_forward_kernel(__global const real* X,
                                 __global const real* W,
                                 __global const real* b,
                                 __global real* Y,
                                 const int num_samples,
                                 const int in_features,
                                 const int out_features) {
    int id = get_global_id(0);
    int total_elements = num_samples * out_features;

    if (id < total_elements) {
        int row = id % num_samples;
        int col = id / num_samples;

        real sum = (real)0.0f;
        for (int k = 0; k < in_features; ++k) {
            sum += X[k * num_samples + row] * W[col * in_features + k];
        }
        sum += b[col];
        Y[id] = compute_sigmoid(sum);
    }
}
'
writeLines(nn_kernels_src, "./nn_forward_kernel.cl")


## ----create_forward_only_interface--------------------------------------------
forward_interface_src <- '
NumericMatrix r_X(X);
NumericMatrix r_W(W);
NumericVector r_b(b);

int num_samples  = r_X.nrow();
int in_features  = r_X.ncol();
int out_features = r_W.ncol();

NumericMatrix r_Y(num_samples, out_features);

int size_X = num_samples * in_features;
int size_W = in_features * out_features;
int size_Y = num_samples * out_features;

Memory<real> gpu_X(*device, size_X);
Memory<real> gpu_W(*device, size_W);
Memory<real> gpu_b(*device, out_features);
Memory<real> gpu_Y(*device, size_Y);

for(int i = 0; i < size_X; ++i) gpu_X[i] = r_X[i];
for(int i = 0; i < size_W; ++i) gpu_W[i] = r_W[i];
for(int i = 0; i < out_features; ++i) gpu_b[i] = r_b[i];

gpu_X.write_to_device();
gpu_W.write_to_device();
gpu_b.write_to_device();

Kernel k_fwd(*device, (ulong)size_Y, "dense_forward_kernel",
             gpu_X, gpu_W, gpu_b, gpu_Y, num_samples, in_features, out_features);
k_fwd.run();

gpu_Y.read_from_device();
for(int i = 0; i < size_Y; ++i) r_Y[i] = gpu_Y[i];

return r_Y;
'
writeLines(forward_interface_src, "./nn_forward_rcpp.cpp")


## ----create_forward_only_pipeline---------------------------------------------
nn_forward_gpu <- (function() {
  .forward_internal <- NULL
  function(X_mat, W_mat, b_vec) {
    if (is.null(.forward_internal)) {
      .forward_internal <<- OpenCLeaR::oclFunction(
        signature      = signature(X = "matrix", W = "matrix", b = "numeric"),
        kernel_file    = "./nn_forward_kernel.cl",
        interface_file = "./nn_forward_rcpp.cpp",
        math_lib       = "./libkernel.cl"
      )
    }
    return(.forward_internal(X = X_mat, W = W_mat, b = b_vec))
  }
})()


## ----initialize_forward_only_pipeline-----------------------------------------
silent_warmup_nnet <- nn_forward_gpu(as.matrix(1:25,5,5), as.matrix(runif(25),5,5), 5:1)

set.seed(123)
test_X <- matrix(runif(200 * 50, -1, 1), nrow = 200)
test_W <- matrix(runif(50 * 30, -0.1, 0.1), nrow = 50)
test_b <- runif(30, -0.5, 0.5)

start_cpu_nnet <- Sys.time()
res_nnet_cpu   <- 1 / (1 + exp(-((test_X %*% test_W) + matrix(test_b, nrow = 200, ncol = 30, byrow = TRUE))))
end_cpu_nnet <- Sys.time()
time_cpu_nnet <- as.numeric(difftime(end_cpu_nnet, start_cpu_nnet, units = "secs"))
start_gpu_nnet <- Sys.time()
res_nnet_gpu <- nn_forward_gpu(test_X, test_W, test_b)
end_gpu_nnet <- Sys.time()
time_gpu_nnet <- as.numeric(difftime(end_gpu_nnet, start_gpu_nnet, units = "secs"))

max_diff_nnet <- max(abs(res_nnet_cpu - res_nnet_gpu))
cat("📊 Forward Pass Max Discrepancy:", max_diff_nnet, "\n")
cat("⏱️ CPU Vector Time:", round(time_cpu_nnet, 4), "s\n")
cat("⏱️ GPU Vector Time:", round(time_gpu_nnet, 4), "s (Speedup:", round(time_cpu_nnet / time_gpu_nnet, 2), "x)\n")


## ----create_extended_math_library---------------------------------------------
libkernel_src <- '
static inline real compute_sigmoid(real x) {
    return (real)1.0f / ((real)1.0f + exp(-x));
}

static inline real d_sigmoid(real sigmoid_y) {
    return sigmoid_y * ((real)1.0f - sigmoid_y);
}
'
writeLines(libkernel_src, "./libkernel.cl")


## ----create_backward_kernels--------------------------------------------------
nn_kernels_src_extended <- '
__kernel void dense_backward_delta_kernel(__global const real* dY,
                                         __global const real* Y,
                                         __global real* dL,
                                         const int total_elements) {
    int id = get_global_id(0);
    if (id < total_elements) {
        dL[id] = dY[id] * d_sigmoid(Y[id]);
    }
}

__kernel void dense_backward_weights_kernel(__global const real* X,
                                          __global const real* dL,
                                          __global real* dW,
                                          const int num_samples,
                                          const int in_features,
                                          const int out_features) {
    int id = get_global_id(0);
    int total_elements = in_features * out_features;

    if (id < total_elements) {
        int row_w = id % in_features;
        int col_w = id / in_features;

        real sum = (real)0.0f;
        for (int i = 0; i < num_samples; ++i) {
            sum += X[row_w * num_samples + i] * dL[col_w * num_samples + i];
        }
        dW[id] = sum;
    }
}

__kernel void dense_backward_inputs_kernel(__global const real* dL,
                                         __global const real* W,
                                         __global real* dX,
                                         const int num_samples,
                                         const int in_features,
                                         const int out_features) {
    int id = get_global_id(0);
    int total_elements = num_samples * in_features;

    if (id < total_elements) {
        int row_x = id % num_samples;
        int col_x = id / num_samples;

        real sum = (real)0.0f;
        for (int j = 0; j < out_features; ++j) {
            sum += dL[j * num_samples + row_x] * W[j * in_features + col_x];
        }
        dX[id] = sum;
    }
}

__kernel void dense_backward_bias_kernel(__global const real* dL,
                                        __global real* db,
                                        const int num_samples,
                                        const int out_features) {
    int id = get_global_id(0);
    if (id < out_features) {
        real b_sum = (real)0.0f;
        int col_offset = id * num_samples;
        for (int i = 0; i < num_samples; ++i) {
            b_sum += dL[col_offset + i];
        }
        db[id] = b_sum;
    }
}
'
full_nn_kernels <- paste(nn_kernels_src, nn_kernels_src_extended, sep="\n")
writeLines(full_nn_kernels, "./nn_training_kernels.cl")


## ----create_single_step_rcpp--------------------------------------------------
nn_interface_src <- '
NumericMatrix r_X(X);
NumericMatrix r_W(W);
NumericVector r_b(b);
NumericMatrix r_dY(dY);

int num_samples = r_X.nrow();
int in_features = r_X.ncol();
int out_features = r_W.ncol();

NumericMatrix r_Y(num_samples, out_features);
NumericMatrix r_dW(in_features, out_features);
NumericMatrix r_dX(num_samples, in_features);
NumericVector r_db(out_features);

int size_X = num_samples * in_features;
int size_W = in_features * out_features;
int size_Y = num_samples * out_features;

Memory<real> gpu_X(*device, size_X);
Memory<real> gpu_W(*device, size_W);
Memory<real> gpu_b(*device, out_features);
Memory<real> gpu_Y(*device, size_Y);
Memory<real> gpu_dY(*device, size_Y);
Memory<real> gpu_dL(*device, size_Y);
Memory<real> gpu_dW(*device, size_W);
Memory<real> gpu_dX(*device, size_X);
Memory<real> gpu_db(*device, out_features);

for(int i = 0; i < size_X; ++i) gpu_X[i] = r_X[i];
for(int i = 0; i < size_W; ++i) gpu_W[i] = r_W[i];
for(int i = 0; i < out_features; ++i) gpu_b[i] = r_b[i];
for(int i = 0; i < size_Y; ++i) gpu_dY[i] = r_dY[i];

gpu_X.write_to_device();
gpu_W.write_to_device();
gpu_b.write_to_device();
gpu_dY.write_to_device();

Kernel k_fwd(*device, (ulong)size_Y, "dense_forward_kernel", gpu_X, gpu_W, gpu_b, gpu_Y, num_samples, in_features, out_features);
k_fwd.run();

Kernel k_delta(*device, (ulong)size_Y, "dense_backward_delta_kernel", gpu_dY, gpu_Y, gpu_dL, size_Y);
k_delta.run();

Kernel k_bwd_w(*device, (ulong)size_W, "dense_backward_weights_kernel", gpu_X, gpu_dL, gpu_dW, num_samples, in_features, out_features);
k_bwd_w.run();

Kernel k_bwd_in(*device, (ulong)size_X, "dense_backward_inputs_kernel", gpu_dL, gpu_W, gpu_dX, num_samples, in_features, out_features);
k_bwd_in.run();

Kernel k_bwd_bias(*device, (ulong)out_features, "dense_backward_bias_kernel", gpu_dL, gpu_db, num_samples, out_features);
k_bwd_bias.run();

gpu_Y.read_from_device();
gpu_dW.read_from_device();
gpu_dX.read_from_device();
gpu_db.read_from_device();

for(int i = 0; i < size_Y; ++i) r_Y[i] = gpu_Y[i];
for(int i = 0; i < size_W; ++i) r_dW[i] = gpu_dW[i];
for(int i = 0; i < size_X; ++i) r_dX[i] = gpu_dX[i];
for(int i = 0; i < out_features; ++i) r_db[i] = gpu_db[i];

return List::create(Named("Y") = r_Y, Named("dW") = r_dW, Named("dX") = r_dX, Named("db") = r_db);
'
writeLines(nn_interface_src, "./nn_training_rcpp.cpp")


## ----setup_benchmark_data-----------------------------------------------------
num_samples  <- 2000L
in_features  <- 1500L
out_features <- 10000L
epochs       <- 5L
lr           <- 0.01

set.seed(42)
mat_X  <- matrix(runif(num_samples * in_features, -1, 1), nrow = num_samples)
mat_W  <- matrix(runif(in_features * out_features, -0.1, 0.1), nrow = in_features)
vec_b  <- runif(out_features, -0.5, 0.5)
mat_dY <- matrix(runif(num_samples * out_features, -0.2, 0.2), nrow = num_samples)


## ----run_unoptimized_loop-----------------------------------------------------
nn_single_step_gpu <- (function() {
  .single_step_internal <- NULL
  function(X_mat, W_mat, b_vec, dY_mat) {
    if (is.null(.single_step_internal)) {
      .single_step_internal <<- OpenCLeaR::oclFunction(
        signature      = signature(X = "matrix", W = "matrix", b = "numeric", dY = "matrix"),
        kernel_file    = "./nn_training_kernels.cl",
        interface_file = "./nn_training_rcpp.cpp",
        math_lib       = "./libkernel.cl"
      )
    }
    return(.single_step_internal(X = X_mat, W = W_mat, b = b_vec, dY = dY_mat))
  }
})()

# Warm-up pass to isolate JIT compilation latency
invisible(nn_single_step_gpu(mat_X[1:10, ], mat_W, vec_b, mat_dY[1:10, ]))

# Launch the unoptimized loop driven by R
unopt_W <- mat_W
unopt_b <- vec_b
start_unopt <- Sys.time()

for (e in 1:epochs) {
    grads <- nn_single_step_gpu(X = mat_X, W = unopt_W, b = unopt_b, dY = mat_dY)
    unopt_W <- unopt_W - lr * grads$dW
    unopt_b <- unopt_b - lr * grads$db
}

end_unopt <- Sys.time()
time_unopt <- as.numeric(difftime(end_unopt, start_unopt, units = "secs"))

cat("⏱️ Unoptimized Host-Loop GPU Time (with per-epoch PCIe transfers):", round(time_unopt, 4), "seconds\n")


## ----create_optimizer_kernel--------------------------------------------------
optimizer_kernel_src <- '
__kernel void optimizer_kernel(__global real* W,
                               __global real* b,
                               __global const real* dW,
                               __global const real* db,
                               const real learning_rate,
                               const int size_W,
                               const int out_features) {
    int id = get_global_id(0);
    if (id < size_W) {
        W[id] -= learning_rate * dW[id];
    }
    if (id < out_features) {
        b[id] -= learning_rate * db[id];
    }
}
'
full_kernels_src <- paste(readLines("./nn_training_kernels.cl"), collapse="\n")
full_kernels_src <- paste(full_kernels_src, optimizer_kernel_src, sep="\n")
writeLines(full_kernels_src, "./nn_multi_epoch_kernels.cl")


## ----create_enclosed_loop_rcpp------------------------------------------------
enclosed_interface_src <- '
NumericMatrix r_X(X);
NumericMatrix r_W(W);
NumericVector r_b(b);
NumericMatrix r_dY(dY);
int epochs = as<int>(epochs_in);
real r_lr = as<real>(lr);

int num_samples = r_X.nrow();
int in_features = r_X.ncol();
int out_features = r_W.ncol();

int size_X = num_samples * in_features;
int size_Y = num_samples * out_features;
int size_W = in_features * out_features;

Memory<real> gpu_X(*device, size_X);
Memory<real> gpu_W(*device, size_W);
Memory<real> gpu_b(*device, out_features);
Memory<real> gpu_Y(*device, size_Y);
Memory<real> gpu_dY(*device, size_Y);
Memory<real> gpu_dL(*device, size_Y);
Memory<real> gpu_dW(*device, size_W);
Memory<real> gpu_dX(*device, size_X);
Memory<real> gpu_db(*device, out_features);

for(int i = 0; i < size_X; ++i) gpu_X[i] = r_X[i];
for(int i = 0; i < size_W; ++i) gpu_W[i] = r_W[i];
for(int i = 0; i < out_features; ++i) gpu_b[i] = r_b[i];
for(int i = 0; i < size_Y; ++i) gpu_dY[i] = r_dY[i];

gpu_X.write_to_device();
gpu_W.write_to_device();
gpu_b.write_to_device();
gpu_dY.write_to_device();

Kernel k_fwd(*device, (ulong)size_Y, "dense_forward_kernel", gpu_X, gpu_W, gpu_b, gpu_Y, num_samples, in_features, out_features);
Kernel k_delta(*device, (ulong)size_Y, "dense_backward_delta_kernel", gpu_dY, gpu_Y, gpu_dL, size_Y);
Kernel k_bwd_w(*device, (ulong)size_W, "dense_backward_weights_kernel", gpu_X, gpu_dL, gpu_dW, num_samples, in_features, out_features);
Kernel k_bwd_in(*device, (ulong)size_X, "dense_backward_inputs_kernel", gpu_dL, gpu_W, gpu_dX, num_samples, in_features, out_features);
Kernel k_bwd_bias(*device, (ulong)out_features, "dense_backward_bias_kernel", gpu_dL, gpu_db, num_samples, out_features);

int opt_grid = (size_W > out_features) ? size_W : out_features;
Kernel k_opt(*device, (ulong)opt_grid, "optimizer_kernel", gpu_W, gpu_b, gpu_dW, gpu_db, r_lr, size_W, out_features);

for(int e = 0; e < epochs; ++e) {
    k_fwd.run();
    k_delta.run();
    k_bwd_w.run();
    k_bwd_in.run();
    k_bwd_bias.run();
    k_opt.run();
}

gpu_W.read_from_device();
gpu_b.read_from_device();

NumericMatrix out_W(in_features, out_features);
NumericVector out_b(out_features);
for(int i = 0; i < size_W; ++i) out_W[i] = gpu_W[i];
for(int i = 0; i < out_features; ++i) out_b[i] = gpu_b[i];

return List::create(Named("W") = out_W, Named("b") = out_b);
'
writeLines(enclosed_interface_src, "./nn_train_epochs_rcpp.cpp")


## ----setup_benchmark_environment----------------------------------------------
nn_train_loop_gpu <- (function() {
    .train_loop_internal <- NULL
    function(X_mat, W_mat, b_vec, dY_mat, lr, num_epochs) {
        if (is.null(.train_loop_internal)) {
            .train_loop_internal <<- OpenCLeaR::oclFunction(
                 signature      = signature(X = "matrix", W = "matrix", b = "numeric", dY = "matrix", lr = "numeric", epochs_in = "integer"),
                 kernel_file    = "./nn_multi_epoch_kernels.cl",
                 interface_file = "./nn_train_epochs_rcpp.cpp",
                 math_lib       = "./libkernel.cl"
                 )
        }
        return(.train_loop_internal(X = X_mat, W = W_mat, b = b_vec, dY = dY_mat, lr = lr, epochs_in = num_epochs))
    }
})()


## ----execute warmup step------------------------------------------------------
cat("🔥 Activating OpenCLeaR JIT Warmup...\n")
silent_warmup_loop <- nn_train_loop_gpu(mat_X[1:10, ], mat_W, vec_b, mat_dY[1:10, ], lr, 1L)
cat("✅ JIT-Compiler cache verified.\n\n")


## ----cpu run------------------------------------------------------------------
cat("⏳ Launching Multi-Epoch Neural Loop on CPU...\n")
cpu_W <- mat_W
cpu_b <- vec_b
start_cpu <- Sys.time()

for(e in 1:epochs) {
    cpu_Y  <- 1 / (1 + exp(-( (mat_X %*% cpu_W) + matrix(cpu_b, nrow=num_samples, ncol=out_features, byrow=TRUE) )))
    cpu_dL <- mat_dY * cpu_Y * (1 - cpu_Y)
    cpu_dW <- t(mat_X) %*% cpu_dL
    cpu_W  <- cpu_W - lr * cpu_dW
    cpu_b  <- cpu_b - lr * colSums(cpu_dL)
}
end_cpu <- Sys.time()
time_cpu <- as.numeric(difftime(end_cpu, start_cpu, units = "secs"))


## ----execute_gpu_and_verify---------------------------------------------------
cat("⏳ Launching Multi-Epoch Neural Loop on GPGPU...\n")
start_gpu <- Sys.time()
gpu_loop_res <- nn_train_loop_gpu(mat_X, mat_W, vec_b, mat_dY, lr, epochs)
end_gpu <- Sys.time()
time_gpu <- as.numeric(difftime(end_gpu, start_gpu, units = "secs"))

max_diff_W <- max(abs(cpu_W - gpu_loop_res$W))
max_diff_b <- max(abs(cpu_b - gpu_loop_res$b))
total_final_diff <- max(max_diff_W, max_diff_b)

cat("\n📊 Closed Multi-Epoch Performance Analysis:\n")
cat("⏱️ CPU Loop Processing Time :", round(time_cpu, 4), "seconds\n")
cat("⏱️ GPU Pure Streaming Time  :", round(time_gpu, 4), "seconds\n")
cat("🚀 Absolute Streaming Speedup:", round(time_cpu / time_gpu, 2), "x faster on GPU!\n\n")

cat("📊 Bitwise Verification Maximum Error:", total_final_diff, "\n")
if(total_final_diff < 1e-6) {
    cat("✅ Verification PASSED! Enclosed loops are mathematically uniform.\n")
} else {
    cat("⚠️ Warning: Layout misalignment caught outside variance limit.\n")
}



## ----intel--------------------------------------------------------------------
ActivateDevice(1)
GetActiveDeviceInfo()
silent_warmup_loop <- nn_train_loop_gpu(mat_X[1:10, ], mat_W, vec_b, mat_dY[1:10, ], lr, 1L)


## ----execute_gpu_and_verify float---------------------------------------------
cat("⏳ Launching Multi-Epoch Neural Loop on GPGPU...\n")
start_gpu <- Sys.time()
gpu_loop_res <- nn_train_loop_gpu(mat_X, mat_W, vec_b, mat_dY, lr, epochs)
end_gpu <- Sys.time()
time_gpu <- as.numeric(difftime(end_gpu, start_gpu, units = "secs"))

max_diff_W <- max(abs(cpu_W - gpu_loop_res$W))
max_diff_b <- max(abs(cpu_b - gpu_loop_res$b))
total_final_diff <- max(max_diff_W, max_diff_b)

cat("\n📊 Closed Multi-Epoch Performance Analysis:\n")
cat("⏱️ CPU Loop Processing Time :", round(time_cpu, 4), "seconds\n")
cat("⏱️ GPU Pure Streaming Time  :", round(time_gpu, 4), "seconds\n")
cat("🚀 Absolute Streaming Speedup:", round(time_cpu / time_gpu, 2), "x faster on GPU!\n\n")

cat("📊 Bitwise Verification Maximum Error:", total_final_diff, "\n")
if(total_final_diff < 1e-6) {
    cat("✅ Verification PASSED! Enclosed loops are mathematically uniform.\n")
} else {
    cat("⚠️ Warning: Layout misalignment caught outside variance limit.\n")
}


## ----oclFunction with force float---------------------------------------------
ActivateDevice(0)
nn_train_loop_gpu_float <- (function() {
    .train_loop_float_internal <- NULL
    function(X_mat, W_mat, b_vec, dY_mat, lr, num_epochs) {
        if (is.null(.train_loop_float_internal)) {
            .train_loop_float_internal <<- OpenCLeaR::oclFunction(
                signature      = signature(X = "matrix", W = "matrix", b = "numeric", dY = "matrix", lr = "numeric", epochs_in = "integer"),
                kernel_file    = "./nn_multi_epoch_kernels.cl",
                interface_file = "./nn_train_epochs_rcpp.cpp",
                math_lib       = "./libkernel.cl",
                force_float = TRUE # <--- !!
                )
        }
        return(.train_loop_float_internal(X = X_mat, W = W_mat, b = b_vec, dY = dY_mat, lr = lr, epochs_in = num_epochs))
    }
})()

silent_warmup_loop <- nn_train_loop_gpu_float(mat_X[1:10, ], mat_W, vec_b, mat_dY[1:10, ], lr, 1L)


## ----execute_gpu_and_verify float on nvidia-----------------------------------
cat("⏳ Launching Multi-Epoch Neural Loop on GPGPU...\n")
start_gpu <- Sys.time()
gpu_loop_res <- nn_train_loop_gpu_float(mat_X, mat_W, vec_b, mat_dY, lr, epochs)
end_gpu <- Sys.time()
time_gpu <- as.numeric(difftime(end_gpu, start_gpu, units = "secs"))

max_diff_W <- max(abs(cpu_W - gpu_loop_res$W))
max_diff_b <- max(abs(cpu_b - gpu_loop_res$b))
total_final_diff <- max(max_diff_W, max_diff_b)

cat("\n📊 Closed Multi-Epoch Performance Analysis:\n")
cat("⏱️ CPU Loop Processing Time :", round(time_cpu, 4), "seconds\n")
cat("⏱️ GPU Pure Streaming Time  :", round(time_gpu, 4), "seconds\n")
cat("🚀 Absolute Streaming Speedup:", round(time_cpu / time_gpu, 2), "x faster on GPU!\n\n")

cat("📊 Bitwise Verification Maximum Error:", total_final_diff, "\n")
if(total_final_diff < 1e-6) {
    cat("✅ Verification PASSED! Enclosed loops are mathematically uniform.\n")
} else {
    cat("⚠️ Warning: Layout misalignment caught outside variance limit.\n")
}


## ----add_loss_kernel----------------------------------------------------------
loss_kernel_src <- '
__kernel void mse_grad_kernel(__global const real* Y_pred,
                              __global const real* Y_true,
                              __global real* dY,
                              const int total_elements) {
    int id = get_global_id(0);
    if (id < total_elements) {
        dY[id] = ((real)2.0f / (real)total_elements) * (Y_pred[id] - Y_true[id]);
    }
}
'
full_stat_kernels <- paste(readLines("./nn_multi_epoch_kernels.cl"), collapse = "\n")
full_stat_kernels <- paste(full_stat_kernels, loss_kernel_src, sep = "\n")
writeLines(full_stat_kernels, "./nn_stat_kernels.cl")


## ----create_stat_rcpp---------------------------------------------------------
stat_interface_src <- '
NumericMatrix r_X(X);
NumericMatrix r_W(W);
NumericVector r_b(b);
NumericMatrix r_Y_true(Y_true);
int epochs = as<int>(epochs_in);
real r_lr = as<real>(lr);

int num_samples  = r_X.nrow();
int in_features  = r_X.ncol();
int out_features = r_W.ncol();

int size_X = num_samples * in_features;
int size_Y = num_samples * out_features;
int size_W = in_features * out_features;

Memory<real> gpu_X(*device, size_X);
Memory<real> gpu_W(*device, size_W);
Memory<real> gpu_b(*device, out_features);
Memory<real> gpu_Y(*device, size_Y);
Memory<real> gpu_Y_true(*device, size_Y);
Memory<real> gpu_dY(*device, size_Y);
Memory<real> gpu_dL(*device, size_Y);
Memory<real> gpu_dW(*device, size_W);
Memory<real> gpu_dX(*device, size_X);
Memory<real> gpu_db(*device, out_features);

for(int i = 0; i < size_X; ++i) gpu_X[i] = r_X[i];
for(int i = 0; i < size_W; ++i) gpu_W[i] = r_W[i];
for(int i = 0; i < out_features; ++i) gpu_b[i] = r_b[i];
for(int i = 0; i < size_Y; ++i) gpu_Y_true[i] = r_Y_true[i];

gpu_X.write_to_device();
gpu_W.write_to_device();
gpu_b.write_to_device();
gpu_Y_true.write_to_device();

Kernel k_fwd(*device, (ulong)size_Y, "dense_forward_kernel", gpu_X, gpu_W, gpu_b, gpu_Y, num_samples, in_features, out_features);
Kernel k_loss(*device, (ulong)size_Y, "mse_grad_kernel", gpu_Y, gpu_Y_true, gpu_dY, size_Y);
Kernel k_delta(*device, (ulong)size_Y, "dense_backward_delta_kernel", gpu_dY, gpu_Y, gpu_dL, size_Y);
Kernel k_bwd_w(*device, (ulong)size_W, "dense_backward_weights_kernel", gpu_X, gpu_dL, gpu_dW, num_samples, in_features, out_features);
Kernel k_bwd_in(*device, (ulong)size_X, "dense_backward_inputs_kernel", gpu_dL, gpu_W, gpu_dX, num_samples, in_features, out_features);
Kernel k_bwd_bias(*device, (ulong)out_features, "dense_backward_bias_kernel", gpu_dL, gpu_db, num_samples, out_features);

int opt_grid = (size_W > out_features) ? size_W : out_features;
Kernel k_opt(*device, (ulong)opt_grid, "optimizer_kernel", gpu_W, gpu_b, gpu_dW, gpu_db, r_lr, size_W, out_features);

for(int e = 0; e < epochs; ++e) {
    k_fwd.run();
    k_loss.run();
    k_delta.run();
    k_bwd_w.run();
    k_bwd_in.run();
    k_bwd_bias.run();
    k_opt.run();
}

gpu_W.read_from_device();
gpu_b.read_from_device();
gpu_Y.read_from_device();

NumericMatrix out_W(in_features, out_features);
NumericVector out_b(out_features);
NumericMatrix out_Y(num_samples, out_features);
for(int i = 0; i < size_W; ++i) out_W[i] = gpu_W[i];
for(int i = 0; i < out_features; ++i) out_b[i] = gpu_b[i];
for(int i = 0; i < size_Y; ++i) out_Y[i] = gpu_Y[i];

return List::create(Named("W") = out_W, Named("b") = out_b, Named("Y_pred") = out_Y);
'
writeLines(stat_interface_src, "./nn_stat_rcpp.cpp")


## ----run_stat_application-----------------------------------------------------
nn_classify_gpu <- (function() {
  .cls_internal <- NULL
  function(X_mat, W_mat, b_vec, Y_mat, lr, num_epochs) {
    if (is.null(.cls_internal)) {
      .cls_internal <<- OpenCLeaR::oclFunction(
        signature      = signature(X = "matrix", W = "matrix", b = "numeric", Y_true = "matrix", lr= "numeric", epochs_in = "integer"),
        kernel_file    = "./nn_stat_kernels.cl",
        interface_file = "./nn_stat_rcpp.cpp",
        math_lib       = "./libkernel.cl"
      )
    }
    return(.cls_internal(X = X_mat, W = W_mat, b = b_vec, Y_true = Y_mat, lr = lr, epochs_in = num_epochs))
  }
})()

# 1. Generate synthetic 2D non-linear classification dataset
set.seed(2026)
N <- 2000L
x1 <- runif(N, -2, 2)
x2 <- runif(N, -2, 2)

# Polynomial design matrix (linear, quadratic, and interaction terms)
X_design <- cbind(x1, x2, x1^2, x2^2, x1 * x2)
true_logit <- 2.5 - 1.8 * x1^2 - 1.8 * x2^2 + 0.8 * x1 * x2
true_prob  <- 1 / (1 + exp(-true_logit))
y_obs      <- matrix(rbinom(N, size = 1, prob = true_prob), ncol = 1)

# 2. Initialize parameters and train for 2,000 epochs entirely inside GPU VRAM
W_init <- matrix(rnorm(ncol(X_design), sd = 0.1), nrow = ncol(X_design), ncol = 1)
b_init <- 0.0

fit_gpu <- nn_classify_gpu(X_design, W_init, b_init, y_obs, lr = 2.0, num_epochs = 2000L)

# 3. Evaluate estimated parameters and classification accuracy
pred_prob  <- as.vector(fit_gpu$Y_pred)
pred_class <- ifelse(pred_prob >= 0.5, 1, 0)
accuracy   <- mean(pred_class == as.vector(y_obs))

cat("Estimated Weights:", round(as.vector(fit_gpu$W), 3), "\n")
cat("True Weights     : 0.000, 0.000, -1.800, -1.800, 0.800\n")
cat("Estimated Bias   :", round(fit_gpu$b, 3), "(True: 2.500)\n")
cat("Classification Accuracy:", round(accuracy * 100, 2), "%\n")


## ----cleanup------------------------------------------------------------------
CleanCLCache()
unlink(c(
  "./libkernel.cl", 
  "./sigmoid_add_kernel.cl", "./sigmoid_add_rcpp.cpp",
  "./nn_forward_kernel.cl", "./nn_forward_rcpp.cpp",
  "./nn_training_kernels.cl", "./nn_training_rcpp.cpp", 
  "./nn_multi_epoch_kernels.cl", "./nn_train_epochs_rcpp.cpp",
  "./nn_stat_kernels.cl", "./nn_stat_rcpp.cpp"
))


## ----plot_decision_boundary, fig.width=8, fig.height=6------------------------
library(ggplot2)

# Create a fine 2D grid over [-2, 2] x [-2, 2]
grid_seq  <- seq(-2, 2, length.out = 150)
grid_df   <- expand.grid(x1 = grid_seq, x2 = grid_seq)
grid_X    <- with(grid_df, cbind(x1, x2, x1^2, x2^2, x1 * x2))

# Compute predicted probabilities on the grid using our learned GPU parameters
grid_logit       <- as.vector(grid_X %*% fit_gpu$W) + fit_gpu$b
grid_df$prob_hat <- 1 / (1 + exp(-grid_logit))

obs_df <- data.frame(
  x1    = x1,
  x2    = x2,
  Class = factor(as.vector(y_obs), labels = c("Class 0", "Class 1"))
)

ggplot() +
  geom_raster(data = grid_df, aes(x = x1, y = x2, fill = prob_hat), lr = 0.75) +
  geom_contour(data = grid_df, aes(x = x1, y = x2, z = prob_hat),
               breaks = 0.5, color = "black", linewidth = 1.1) +
  geom_point(data = obs_df, aes(x = x1, y = x2, color = Class),
             lr = 0.55, size = 1.4) +
  scale_fill_gradient2(low = "#2b8cbe", mid = "#f7f7f7", high = "#e34a33",
                       midpoint = 0.5, name = "Est. P(Y=1)") +
  scale_color_manual(values = c("Class 0" = "#08519c", "Class 1" = "#a50f15")) +
  labs(
    title    = "GPGPU-Trained Non-Linear Classifier: Learned Decision Boundary",
    subtitle = "Black contour indicates the estimated P(Y = 1 | x1, x2) = 0.5 boundary after 2,000 VRAM epochs",
    x        = expression(x[1]),
    y        = expression(x[2])
  ) +
  theme_minimal() +
  theme(legend.position = "right")

