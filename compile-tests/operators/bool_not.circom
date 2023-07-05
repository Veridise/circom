pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && circom --llvm -o %t %s

template BoolNot() {
    signal input a, b;
    signal output out;

    out <-- !(a < b) ? 1 : 0;
}

component main = BoolNot();
