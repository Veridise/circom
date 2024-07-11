pragma circom 2.0.2;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

template OR() {
    signal input a;
}

// This test demonstrates the need for the UnusedFuncRemovalPass.
// Here's what happens without that pass. The outer loop unrolls first, with 2 copies of its body
//  because it has 2 iterations. In the second iteration (i.e. the second copy of the inner loop),
//  the 'true' branch of the if-else will never execute so in the "loop.body" function generated
//  for that second copy of the inner loop, this branch is dead code. Because it is dead code, no
//  parameter was added to the generated function to reference the destination of the StoreBucket
//  in that branch and therefore the location information in that StoreBucket was not updated thus
//  leaving an invalid parameter reference that causes 'functions.rs::get_arg_ptr' to crash.
//
template InvalidArgIndex(n, k) {
    component has_prev_non_zero[k * n];
    for (var i = k - 1; i >= 0; i--) {
        for (var j = n - 1; j >= 0; j--) {
            has_prev_non_zero[n * i + j] = OR();
            if (i == k - 1 && j == n - 1) {
                has_prev_non_zero[n * i + j].a <-- 99;
            } else {
                has_prev_non_zero[n * i + j].a <-- 33;
            }
        }
    }
}

component main = InvalidArgIndex(3, 2);

//// Check that only the proper versions of the generated functions remain
//// (i.e. the initial one was removed after conditional flattening).
//
//CHECK-NOT: define{{.*}} void @..generated..loop.body.{{[0-9a-zA-Z_\.]+}}(
//CHECK:     define{{.*}} void @..generated..loop.body.[[NAME_1:[0-9a-zA-Z_\.]+]].T.T(
//CHECK-NOT: define{{.*}} void @..generated..loop.body.{{[0-9a-zA-Z_\.]+}}(
//CHECK:     define{{.*}} void @..generated..loop.body.[[NAME_1]].F.T(
//CHECK-NOT: define{{.*}} void @..generated..loop.body.{{[0-9a-zA-Z_\.]+}}(
//CHECK:     define{{.*}} void @..generated..loop.body.[[NAME_2:[0-9a-zA-Z_\.]+]].F.T(
//CHECK-NOT: define{{.*}} void @..generated..loop.body.{{[0-9a-zA-Z_\.]+}}(
