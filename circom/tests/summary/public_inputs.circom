pragma circom 2.0.0;

// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --summary -o %t %s  | sed -n 's/.*Written summary successfully:.* \(.*\)/\1/p' | xargs cat | jq -r '.components[] | select(.main).signals[] | select(.public).name' | sort | FileCheck %s

// CHECK-LABEL: a
// CHECK: b

template B() {
    signal input a;
    signal input b;
    signal output c;

    c <== a * b;
}

template A() {
    signal input a;
    signal input b;
    signal input d;
    signal output c;
    signal x;

    component cb = B();
    cb.a <== a;
    cb.b <== b;

    x <== cb.c;
    c <== x * d;
}

component main {public [a, b]} = A();