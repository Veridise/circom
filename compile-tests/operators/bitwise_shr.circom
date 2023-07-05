pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && circom --llvm -o %t %s

template BitwiseShiftRight() {
    signal input v;
    signal output type;
    signal check_v;
    type <-- v >> 5;
    check_v <== type*32;
}

component main = BitwiseShiftRight();
