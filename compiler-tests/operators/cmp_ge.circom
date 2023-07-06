pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && circom --llvm -o %t %s

template CmpGE(n) {
    signal input a[n];
    signal output b[n];

    for (var i = n-1; i >= 0; i--) {
      b[i] <== a[i];
    }
}

component main = CmpGE(5);
