pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && circom --llvm -o %t %s

template Simple1() {
    signal input a;
    signal output b;
    signal output c;

    b <== a;
    c <== a;
}

component main = Simple1();
