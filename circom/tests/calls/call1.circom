pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && circom --llvm -o %t %s

template B() {
    signal input a;
    signal input b;
    signal output x;

    x <== a * b;
}

template Call1() {
    signal input m;
    signal input n;
    signal output y;

    component a = B();
    a.a <== m;
    a.b <== n;
    // Call to A should happen here
    y <== a.x;
}

component main = Call1();
