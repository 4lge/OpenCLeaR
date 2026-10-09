mat=matrix(rnorm(100*3),100,3)

 distance <- oclFunction(
   signature = signature(mat="numeric"),
   kernel_file = "distance.cl",
   interface_file  = "distance.cpp"
 )

ret = distance(mat)

ret
