// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llzk -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope
// XFAIL:.*

pragma circom 2.1.0;

template Bits2Num(n) {
    signal input {binary} in[n];
    signal output {maxbit} out;
    var lc1=0;

    var e2 = 1;
    for (var i = 0; i<n; i++) {
        lc1 += in[i] * e2;
        e2 = e2 + e2;
    }
    out.maxbit = n;
    lc1 ==> out;
}

template Caller(n) {
    signal input in[n];
    signal output out <== Bits2Num(n)(in);
}

component main = Caller(64);
//CHECK-LABEL:  module attributes {veridise.lang = "llzk"} {
