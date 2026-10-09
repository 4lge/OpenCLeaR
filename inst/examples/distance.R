
mat=rbind(c(1,2,3),
          c(0,0,0),
          c(-1,2,3),
          c(0,1,0),
          c(1,0,0))
mat=matrix(rnorm(5000*3),5000,3)
distance <- oclFunction(
   signature = signature(mat="numeric"),
   kernel_file = "distance.cl",
   interface_file  = "distance.cpp",
   math_lib = FALSE,
   force_float=F,
   verbose = T
 )

system.time(ret <- distance(mat))

str(ret)
