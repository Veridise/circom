pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

template VariantIndex(n) {
    signal input in;
    signal output out[n*n];

    //Cannot move loop body to a new function. The index for 'out' is computed within
    //  the loop body which means a pointer to out[x] obtained at the call site for
    //  the new function and passed as a parameter would point to the wrong memory
    //  location because it will use the old value of 'x'.
    var x = 1;
    for (var i = 0; i<n; i++) {
        x = x + i;
        out[x] <-- (in >> i);
    }
}

component main = VariantIndex(2);

// %0 (i.e. signal arena) = [ out[0], out[1], in ]
// %lvars =  [ n, lc1, e2, i ]
// %subcmps = []
//
//CHECK-LABEL: define void @VariantIndex_{{[0-9]+}}_run
//CHECK-SAME: ([0 x i256]* %[[ARG:[0-9]+]])
//CHECK: unrolled_loop{{[0-9]+}}:
//CHECK-NOT: call void @..generated..loop.body.{{.*}}
