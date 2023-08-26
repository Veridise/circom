pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s

template InnerLoops(n) {
    signal input a[n];
    var b[n];

    for (var j = 0; j <= 0; j++) {
        b[0] = a[0 - j];
    }
    for (var j = 0; j <= 1; j++) {
        b[1] = a[1 - j];
    }
    for (var j = 0; j <= 2; j++) {
        b[2] = a[2 - j];
    }
    for (var j = 0; j <= 3; j++) {
        b[3] = a[3 - j];
    }
    for (var j = 0; j <= 4; j++) {
        b[4] = a[4 - j];
    }
}

component main = InnerLoops(5);
