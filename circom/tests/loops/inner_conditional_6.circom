pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope
// XFAIL: .*    // pending https://veridise.atlassian.net/browse/VAN-677

// if condition is NOT known, arrays used inside indexed on iteration variable
// UPDATE: Circom compiler does not allow the commented block
template InnerConditional6(N) {
    signal output out[N];
    signal input in[N];

    for (var i = 0; i < N; i++) {
        // if (in[i] == 0) {
        //     out[i] <-- 999;
        // } else {
        //     out[i] <-- 888;
        // }
        var x;
        if (in[i] == 0) {
            x = 999;
        } else {
            x = 888;
        }
        out[i] <-- x;
    }
}

component main = InnerConditional6(4);

//CHECK-LABEL: define void @InnerConditional6{{[0-9]+}}_run
//CHECK-SAME: ([0 x i256]* %[[ARG:[0-9]+]])
//CHECK: TODO
