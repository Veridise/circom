pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s
// XFAIL: .*

function sum(a) {
    return a[0] + a[1] + a[2] + a[3];
}

template CallWithArray() {
    signal input x[4];
    signal output y;

    y <-- sum(x);
}

component main = CallWithArray();

//CHECK-LABEL: define void @CallWithArray_{{[0-9]+}}_run
//CHECK-SAME: ([0 x i256]* %[[ARG:[0-9]+]])
//CHECK: TODO: Code produced currently is incorrect! See https://veridise.atlassian.net/browse/VAN-611
