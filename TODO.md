
# Idea:

try the follwoing:

+ create a template OpenCL kernel for e.g. MH 
+ create a concrete implementation of it by specifying distrubtions
  to sample from.
+ create inline::cxxfunction which in turn 
  + loads and compiles this kernel
  + creates CPU/GPU memory objects via OpenCL-Wrapper objects
  + runs the kernel and 
  + returns

This will need 
+ an inlineCxxPlugin defined fir this library to be able to
  link against libBACKEND.so
+ more copy jobs to copy header files via "inst" to be usable at runtime
  not only at package comile time
