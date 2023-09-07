pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope
// XFAIL:.*

// %0 (i.e. signal arena)  = [ out[0], out[1], out[2], out[3], out[4], in ]
// %lvars =  [ n, lc1, e2, i ]
// %subcmps = []
template Num2Bits(n) {
    signal input in;
    signal output out[n*n];
//     signal output out[n];
    for (var i = 0; i < n; i++) {
    	for (var j = 0; j < n; j++) {
        	out[i*n + j] <-- (in >> j) & 1;
        }
//         out[i] <-- (in >> i) & 1;
    }
}

component main = Num2Bits(5);

//NOTE: For indexing dependent on the loop variable, need to compute pointer
//	reference outside of the function call. All else can be done inside.
//Q: What if there are more complex loop conditions? Or multiple iteration variables?
// 
//With array storage allocation:
// template Num2Bits(arena[6]*) {
// 	   lvars[4];
// 	   subcmps[0];
// 	
//     lvars[1] = 0;
//     lvars[2] = 1;
//     for (var i = 0; i < lvars[0]; i++) {  // i == lvars[3]
//         arena[i] <-- (arena[5] >> i) & 1;
//         lvars[1] += arena[i] * lvars[2];
//         lvars[2] = lvars[2] + lvars[2];
//     }
// 
//     lvars[1] === arena[5];
// }
//
//With loop body extracted:
// function loop_body(arena[6]*, lvars[4]*, subcmps[0]*, i, arena_i*) {
//     arena_i <-- (arena[5] >> i) & 1;
//     lvars[1] += arena_i * lvars[2];
//     lvars[2] = lvars[2] + lvars[2];
// }
// template Num2Bits(arena[6]*) {
//     lvars[4];
//     subcmps[0];
// 	
//     lvars[1] = 0;
//     lvars[2] = 1;
//     for (var i = 0; i < lvars[0]; i++) {  // i == lvars[3]
//         loop_body(arena, &lvars, &subcmps, i, %arena[i]);
//     }
// 
//     lvars[1] === arena[5];
// }
//








