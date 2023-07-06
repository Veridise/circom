pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && circom --llvm -o %t %s

template ForKnown(N) {
    signal output out;

    var acc = 0;
    for (var i = 1; i <= N; i++) {
        acc += i;
    }

    out <-- acc;
}

component main = ForKnown(10);