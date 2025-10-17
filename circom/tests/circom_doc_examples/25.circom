// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llzk -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope
// XFAIL:.*

pragma circom 2.1.0;

template A(n){
   signal input a, b, c;
   signal output d;
   d <== a*b+c;
   a * b === c;
}
template B(n){
   signal input in[n];
   _ <== A(n)(in[0],in[1],in[2]);
}
component main = B(3);
// CHECK: TODO
