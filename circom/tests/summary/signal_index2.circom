pragma circom 2.0.0;

// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --summary -o %t %s  | sed -n 's/.*Written summary successfully:.* \(.*\)/\1/p' | xargs cat | jq -r '.components[].signals[] | {name: .name, idx: .idx }[]' | FileCheck %s

//      CHECK: c[0]
// CHECK-NEXT: 0
// CHECK-NEXT: c[1]
// CHECK-NEXT: 1
// CHECK-NEXT: c[2]
// CHECK-NEXT: 2
// CHECK-NEXT: c[3]
// CHECK-NEXT: 3
// CHECK-NEXT: a[0]
// CHECK-NEXT: 4
// CHECK-NEXT: a[1]
// CHECK-NEXT: 5
// CHECK-NEXT: b[0]
// CHECK-NEXT: 6
// CHECK-NEXT: b[1]
// CHECK-NEXT: 7
// CHECK-NEXT: x
// CHECK-NEXT: 8

template B() {
    signal input a;
    signal input b;
    signal output c;

    c <== a * b;
}

template A() {
    signal input a[2];
    signal input b[2];
    signal output c[4];
    signal x;

    for (var i = 0; i < 4; i++) {
        if (i % 2 == 0) {
            c[i] <== a[i \ 2];
        } else {
            c[i] <== b[i \ 2];
        }
    }

    x <== c[0];
}

component main {public [a, b]} = A();