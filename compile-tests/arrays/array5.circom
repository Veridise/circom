pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && not circom --llvm -o %t %s 2>&1 | FileCheck %s

template A(n) {
  signal input a[n];
  signal output b[n];

  for (var i = 0; i < n; i++) {
    b[i] <== a[i];
  }
}

template Array5(n) {
    signal input a[n];
    signal output b[n];

    component a_cmp = A(n);

    for (var i = 0; i < n; i++) {
      a_cmp.a[0] <== a[i]; //FAIL: assigns to a_cmp.a[0] more than once
    }

    for (var i = 0; i < n; i++) {
      a_cmp.b[i] ==> b[i];
    }
}

component main = Array5(5);

//CHECK-LABEL: Exception caused by invalid assignment: 
//CHECK-SAME:  signal already assigned
