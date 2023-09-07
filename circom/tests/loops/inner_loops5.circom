pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope


// %0 (i.e. signal arena)  = [ out, in ]
// %lvars =  [ n, temp, i, j ]
// %subcmps = []
template Num2Bits(n) {
    signal input in;
    signal output out;

	var temp = 0;
    for (var i = 0; i < n; i++) {
    	for (var j = 0; j < n; j++) {
        	temp += (in >> j) & 1;
        }
    }
}

component main = Num2Bits(4);
