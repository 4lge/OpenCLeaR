mat=matrix(rnorm(5000*3),5000,3)
mat=rbind(c(1,2,3),
          c(0,0,0),
          c(-1,2,3),
          c(0,1,0),
          c(1,0,0))
 distance <- oclFunction(
   signature = signature(mat="numeric"),
   kernel_file = "distance.cl",
   interface_file  = "distance.cpp",
   math_lib = FALSE,
   force_float=T,
   verbose = T
 )

ret = distance(mat)

ret
