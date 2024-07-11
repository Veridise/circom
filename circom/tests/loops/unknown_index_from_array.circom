pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

// %0 (i.e. signal arena) = [ c[0], c[1], c[2] , a[0], a[1], a[2], b[0], b[1], b[2] ]
// %lvars = [ n, i ]
template Example(n) {
    signal input a[n];
    signal input b[n];
    signal output c[n];

    for(var i = 0; i < n; i++) {
        c[i] <-- a[b[2]];
    }
}

component main = Example(3);

//CHECK-LABEL: define{{.*}} void @Example_{{[0-9]+}}_run
//CHECK-SAME: ([0 x i256]* %[[ARG:[0-9]+]]){{.*}} {
//CHECK: unrolled_loop{{[0-9]+}}:
//CHECK-NOT: call void @..generated..loop.body.{{.*}}
//
//NOTE: Current implementation of loop body extraction does not move this loop body to
//  a new function because the index of 'a' is unknown (i.e. loaded from signal 'b'). 
