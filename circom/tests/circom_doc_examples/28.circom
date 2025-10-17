// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llzk -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope
// XFAIL:.*

pragma circom 2.1.0;

template A() {
    signal input {binary} in;
    signal intermediate;
    signal output {binary} out;
    intermediate <== in;
    out <== intermediate;
}

template Caller(){
    signal input inp;
    signal output out;
    component a = A();
    a.in <== inp;
    out <== a.out;
}

component main = Caller();
//CHECK-LABEL:  module attributes {veridise.lang = "llzk"} {
