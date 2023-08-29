pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s

template InnerLoops(n) {
    signal input a[n];
    var b[n];

    // Manually unrolled loop from inner_loops.circom
    //for (var i = 0; i < n; i++) {

    var i = 0;
    for (var j = 0; j <= i; j++) {
        b[i] = a[i - j];
    }
    i++; // 1
    for (var j = 0; j <= i; j++) {
        b[i] = a[i - j];
    }
    i++; // 2
    for (var j = 0; j <= i; j++) {
        b[i] = a[i - j];
    }
    i++; // 3
    for (var j = 0; j <= i; j++) {
        b[i] = a[i - j];
    }
    i++; // 4
    for (var j = 0; j <= i; j++) {
        b[i] = a[i - j];
    }
    i++; // 5
}

component main = InnerLoops(5);
