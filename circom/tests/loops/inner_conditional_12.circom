pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

// This test contains inner loops with different iteration counts. Further, one is
//  independent of the outer loop induction variable and the other loop depends on it.
//
// lvars = [ N, a[0], a[1], a[2], a[3], i, j ]
template InnerConditional12(N) {
    signal output out;

    var a[N];
    for (var i = 0; i < N; i++) {
        if (i < 2) {
            // runs when i∈{0,1}
            for (var j = 0; j < N; j++) {
                a[i] += 999;
            }
        } else {
            // runs when i∈{2,3}
            for (var j = 0; j < i; j++) {
                a[i] += 888;
            }
        }
    }
    out <-- a[0] + a[1];
}

component main = InnerConditional12(4);
