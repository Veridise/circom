pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && circom --llvm -o %t %s

template Simple2(a) {
    signal output b;

    b <== a;
}

component main = Simple2(10);
