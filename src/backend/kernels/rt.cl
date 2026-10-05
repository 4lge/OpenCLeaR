// -*- mode: C -*-
    
       kernel void t_rng(global real_t* output, global int* seed, 
			 const int nu) {
	 
         // Initialize Mersenne Twister state
         uint mt[624];
         int idx = 624;
         mt[0] = *seed + get_global_id(0);
         for (int i = 1; i < 624; ++i) {
           mt[i] = (181243 * (mt[i - 1] ^ (mt[i - 1] >> 30)) + i);
         }
         
         real_t r_t = rt(nu, &idx, mt);
         
         output[get_global_id(0)] = r_t;
       }
