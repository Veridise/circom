pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s

template Array0() {
    signal input a[1];
    signal output b[1];

    b[0] <== a[0];
}

component main = Array0();
