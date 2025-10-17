// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llzk -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope
// XFAIL:.*

pragma circom 2.0.0;

template A(n){
   signal input a, b;
   signal output c;
   c <== a*b;
}
template B(n){
   signal input in[n];
   signal out;
   component temp_a = A(n);
   temp_a.a <== in[0]; 
   temp_a.b <== in[1];
   out <== temp_a.c;
}
component main = B(2);
//CHECK-LABEL:  module attributes {veridise.lang = "llzk"} {
