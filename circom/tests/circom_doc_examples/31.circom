// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llzk -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope
// XFAIL:.*

pragma circom 2.1.0;

template A(){
    signal output {max} out[100];
    out[0] <== 1;
    out.max = 10;
}

component main = A();
//CHECK-LABEL:  module attributes {veridise.lang = "llzk"} {
