pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && circom --llvm -o %t %s

template nbits() {
    signal input in;
    signal output out;
    var n = 1;
    var r = 0;
    while (n-1 < in) {
        r++;
        n *= 2;
    }
    out <-- r;
}

template UnknownLoopComponent() {
    signal input num;
    signal output bits;

    component nb = nbits();
    nb.in <-- num;
    bits <-- nb.out;
}

component main = UnknownLoopComponent();