pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && not circom --llvm -o %t %s 2>&1 | FileCheck %s

template A() {
    signal input a;
    signal input b;
    signal output x;

    x <== a + b;
}

template Call1() {
    signal input m;
    signal input n;
    signal output y;

    component a = A();
    a.a <== m;
    // a.b <== n;
    y <== a.x; //FAIL: not all signals were allocated
}

component main = Call1();

//CHECK-LABEL: Exception caused by invalid access:
//CHECK-SAME:  trying to access to an output signal of a component with not all its inputs initialized
