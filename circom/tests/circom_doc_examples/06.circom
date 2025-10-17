// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llzk -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope
// XFAIL:.*

pragma circom 2.0.0;

// This function calculates the number of extra bits 
// in the output to do the full sum.
function nbits(a) {
    var n = 1;
    var r = 0;
    while (n-1<a) {
        r++;
        n *= 2;
    }
    return r;
}

function example(N){
    if (N >= 0) { return 1; }
    else { return 0; }
}

template Caller() {
    signal input in;
    signal output out;

    out <== example(nbits(in));
}

component main = Caller();

//CHECK-LABEL:  module attributes {veridise.lang = "llzk"} {
