// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llzk -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope
// XFAIL:.*

pragma circom 2.1.5;

template A(n){
   signal input in;
   signal output outA;
   var i = 0;
   if(i < n){
    signal out <== 2;
    i = out;
   } 
   outA <== i;
}

component main = A(5);
// CHECK: TODO
