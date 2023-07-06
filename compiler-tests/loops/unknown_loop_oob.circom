pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && circom --llvm -o %t %s

template accumulate() {
    signal input i;
    signal output o;
    var r = 0;
    while (r < i) {
        r++;
    }
    o <-- r;
}

template UnknownLoopOOB() {
    signal input m; // Could be out of bounds
    signal input n[2];
    signal output y;

    component a = accumulate();
    a.i <-- m;
    y <-- n[a.o];
}

component main = UnknownLoopOOB();