pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s

template InnerLoops(n) {
    signal input a[n];
    var b[n];
    var j;
    for (var i = 0; i < n; i++) {
        for (j = 0; j <= i; j++) {
            b[i] = a[i - j];
        }
    }
}

component main = InnerLoops(2);