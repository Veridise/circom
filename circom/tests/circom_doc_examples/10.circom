// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llzk -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope
// XFAIL:.*

pragma circom 2.0.0;

template T14() {
    signal output out;
    var x = 0;
    var y = 1;
    if (x >= 0) {
        x = y + 1;
        y += 1;
    } else {
        y = x;
    }
    out <== x + y;
}

component main = T14();
// CHECK: TODO
