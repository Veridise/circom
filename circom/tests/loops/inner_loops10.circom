pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

template InnerLoops(N) {
    signal input in[N];
    signal output out;
    signal output out2[N];
    var a = 0;
    var b = 0;
    for (var i = 0; i < N; i++) {
        out2[i] <-- in[i] + b;
        for (var j = 0; j < N; j++) {
            a += 99;
        }
        b += 5;
    }
    out <-- a;
}

component main = InnerLoops(2);
