pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && circom --llvm -o %t %s

template CmpGT(n) {
    signal input a[n];
    signal output b[n];

    for (var i = n; i > 0; i--) {
      b[i-1] <== a[i-1];
    }
}

component main = CmpGT(5);
