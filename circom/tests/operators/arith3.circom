pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && not %circom --llvm -o %t %s 2>&1 | FileCheck %s

template Arith3() {
    signal input a;
    signal input b;
    signal input c;
    signal output x;
    x <== a * b * c; //FAIL: quadratic constraint
}

component main = Arith3();

//CHECK-LABEL: Non quadratic constraints are not allowed!
