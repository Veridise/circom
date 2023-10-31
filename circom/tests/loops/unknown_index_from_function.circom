pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

function identity(n) {
    return n;
}

template Example(n) {
    signal input a[n];
    signal input b;
    signal output c[n];
    
    for(var i = 0; i < n; i++) {
        c[i] <-- a[identity(b)];
        //Circom AST splits this into 2 nodes:
        //	CALL: lvars[2] = identity(b)
        //	STORE: c[i] = a[lvars[2]]
        //Then the loop variable increment is the 3rd statement
        //	STORE: i = i + 1
    }
}

component main = Example(3);

// %0 (i.e. signal arena) { c[0], c[1], c[2] , a[0], a[1], a[2], b }
// %lvars = { n, i, <identity_result> }
//
//CHECK-LABEL: define{{.*}} void @Example_{{[0-9]+}}_run
//CHECK-SAME: ([0 x i256]* %[[ARG:[0-9]+]])
//CHECK: unrolled_loop{{[0-9]+}}:
//CHECK-NOT: call void @..generated..loop.body.{{.*}}
//
//NOTE: Current implementation of loop body extraction does not move this loop body to
//  a new function because the index of 'a' is unknown (i.e. function return value). 
