pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s

template Simple4(a) {
    signal output b;
    signal input c;
    signal input d;
    var x;
    var y;

    x = a;
    y = 11;

    b <== a;
}

component main = Simple4(10);
