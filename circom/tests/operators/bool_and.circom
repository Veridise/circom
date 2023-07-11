pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s

template BoolAnd() {
    signal input a, b;
    signal output out;

    out <-- (a > 0 && b > 0) ? 1 : 0;
}

component main = BoolAnd();
