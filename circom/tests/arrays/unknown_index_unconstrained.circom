pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s

template UnknownIndex() {
    signal input in;
    signal output out;

    var arr1[10] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
    var arr2[10] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
    var arr3[10] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];

    // non-quadractic constraint
    // out <== arr[acc];
    out <-- arr2[in];
}

component main = UnknownIndex();