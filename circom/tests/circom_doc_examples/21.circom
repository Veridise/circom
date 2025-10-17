// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llzk -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope
// XFAIL:.*

pragma circom 2.1.0;

template Ex(n,m){ 
   signal input in[n];
   signal output out[m];
   out <== in;
}

component main = Ex(3,3);
// CHECK: TODO
