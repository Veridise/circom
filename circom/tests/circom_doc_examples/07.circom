// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llzk -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope
// XFAIL:.*

pragma circom 2.0.0;

template A(){
    signal input in1;
    signal input in2;
    signal output out;
    out <== in1 * in2;
}

component main {public [in1]}= A();
//CHECK-LABEL:  module attributes {veridise.lang = "llzk"} {
