pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

template InnerLoops(N) {
    signal output out;
    var a = 0;
    var b = 1000;
    for (var i = 0; i < N; i++) {
        b += a;
        for (var j = 0; j < N; j++) {
            a += 99;
        }
        b -= 5;
    }
    out <-- a;
}

component main = InnerLoops(2);

//CHECK: InnerLoops
//TODO
