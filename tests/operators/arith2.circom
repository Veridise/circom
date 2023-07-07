pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && circom --llvm -o %t %s

template Arith2() {
    signal input a;
    signal input b;
    signal input c;
    signal output x;
    x <== a * b * 10;
}

component main = Arith2();
