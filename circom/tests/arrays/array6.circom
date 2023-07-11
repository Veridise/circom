pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && not %circom --llvm -o %t %s 2>&1 | FileCheck %s

template A(n) {
    signal input a;
    signal output b;

    var arr[n];
    var x;

    for (var i = 0; i < n+1; i++) {
      arr[i] = a; //FAIL: assigns to arr[n+1] which is out of bounds
    }
    b <-- x;
}

component main = A(5);

//CHECK-LABEL: Out of bounds exception
