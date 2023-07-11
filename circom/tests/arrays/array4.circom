pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && not %circom --llvm -o %t %s 2>&1 | FileCheck %s

template A(n) {
  signal input a[n];
  signal output b[n];

  for (var i = 0; i < n; i++) {
    b[i] <== a[i];
  }
}

template Array3(n) {
    signal input a[n];
    signal output b[n];

    component a_cmp = A(n+1);

    for (var i = 0; i < n; i++) {
      a_cmp.a[i] <== a[i];
    }

    for (var i = 0; i < n; i++) {
      a_cmp.b[i] ==> b[i]; //FAIL: a_cmp.a[n+1] was not assigned
    }
}

component main = Array3(5);

//CHECK-LABEL: Exception caused by invalid access: 
//CHECK-SAME:  trying to access to an output signal of a component with not all its inputs initialized
