// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llzk -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope
// XFAIL:.*

pragma circom 2.0.0;

template T16() {
    signal output out;
    var y = 0;
    var i = 0;
    while(i < 100){
        i++;
        y += y;
    }
    out <== y;
}

component main = T16();
// CHECK: TODO
