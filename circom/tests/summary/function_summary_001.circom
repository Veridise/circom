pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

function array_computation(x, n) {
    var ret[2];
    var i;
    for (i = 0; i < n \ 2; i++) {
        ret[0] += x[i];
    }
    for (i = n \ 2; i < n; i++) {
        ret[1] += x[i];
    }
    return ret;
}

template Caller() {
    signal input inp[5];
    signal output outp[2] <== array_computation(inp, 5);
}

component main = Caller();

// Ensure that loop body functions are generated without a "section" identifier
//
//CHECK-LABEL: define{{.*}} void @..generated..loop.body.{{[0-9a-zA-Z_\.]+}}([0 x i256]* %lvars, [0 x i256]* %signals,
//CHECK-SAME:  i256* %var_{{[0-9]+}}) #{{[0-9]+}} !dbg !{{[0-9]+}} {
//
//CHECK-LABEL: define{{.*}} void @..generated..loop.body.{{[0-9a-zA-Z_\.]+}}([0 x i256]* %lvars, [0 x i256]* %signals,
//CHECK-SAME:  i256* %var_{{[0-9]+}}) #{{[0-9]+}} !dbg !{{[0-9]+}} {
