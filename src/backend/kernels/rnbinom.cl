// -*- mode: C -*-
    
       kernel void nbinom_rng(global int* output, global int* seed,
                              global int* size, global real_t* prob) {
	 
         // Initialize Mersenne Twister state
         uint mt[624];
         int idx = 624;
         mt[0] = *seed + get_global_id(0);
         for (int i = 1; i < 624; ++i) {
           mt[i] = (181243 * (mt[i - 1] ^ (mt[i - 1] >> 30)) + i);
         }
         
         
         uint r_nbinom = rnbinom(*size, *prob, &idx, mt);
         
         output[get_global_id(0)] = r_nbinom;
       }
