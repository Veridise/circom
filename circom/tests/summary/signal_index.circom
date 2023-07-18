pragma circom 2.0.0;

// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --summary -o %t %s  | sed -n 's/.*Written summary successfully:.* \(.*\)/\1/p' | xargs cat | jq -r '.components[].signals[] | {name: .name, idx: .idx }[]' | FileCheck %s

//      CHECK: c
// CHECK-NEXT: 0
// CHECK-NEXT: a
// CHECK-NEXT: 1
// CHECK-NEXT: b
// CHECK-NEXT: 2
// CHECK-NEXT: c
// CHECK-NEXT: 0
// CHECK-NEXT: a
// CHECK-NEXT: 1
// CHECK-NEXT: b
// CHECK-NEXT: 2
// CHECK-NEXT: x
// CHECK-NEXT: 3

template B() {
    signal input a;
    signal input b;
    signal output c;

    c <== a * b;
}

template A() {
    signal input a;
    signal input b;
    signal output c;
    signal x;

    component cb = B();
    cb.a <== a;
    cb.b <== b;

    x <== cb.c;
    c <== x * 5;
}

component main {public [a, b]} = A();