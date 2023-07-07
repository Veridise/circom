pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && circom --llvm -o %t %s

template MultByInv() {
    signal input in;
    signal output out;

    signal inv;

    inv <-- in != 0 ? 1 / in : 0;

    out <== inv;
    in * out === 0;
}

component main = MultByInv();
