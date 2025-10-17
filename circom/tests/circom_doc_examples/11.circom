// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llzk -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope
// XFAIL:.*

pragma circom 2.0.0;

template T15() {
    signal output out;
    var y = 0;
    for(var i = 0; i < 100; i++){
        y++;
    }
    out <== y;
}

component main = T15();
// CHECK: TODO
