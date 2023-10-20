pragma circom 2.0.2;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s

template OR() {
    signal input a;
}

template InvalidArgIndex(n, k) {
    component has_prev_non_zero[k * n];
    for (var i = k - 1; i >= 0; i--) {
        for (var j = n - 1; j >= 0; j--) {
            has_prev_non_zero[n * i + j] = OR();
            if (i == k - 1 && j == n - 1) {
                // StoreBucket here causes a crash in `get_arg_ptr` 
                // Here's what happens. The outer loop unrolls first, 2 iterations. In the second
                //  iteration, this branch of the if-else will never execute so in the generated
                //  "loop.body" function, this branch is dead code, thus no parameter was added
                //  to the function to reference the destination of this StoreBucket and the 
                //  location information was not updated so there is an invalid parameter reference
                //  that causes 'functions.rs::get_arg_ptr' to crash, but it's in dead code.
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
//CHECK-NOT: define void @..generated..loop.body.[[[0-9]+]](
//CHECK:     define void @..generated..loop.body.[[[0-9]+]].F(
//CHECK-NOT: define void @..generated..loop.body.[[[0-9]+]](
//CHECK:     define void @..generated..loop.body.[[[0-9]+]].T(
//CHECK-NOT: define void @..generated..loop.body.[[[0-9]+]](
//CHECK:     define void @..generated..loop.body.[[[0-9]+]].F.T(
//CHECK-NOT: define void @..generated..loop.body.[[[0-9]+]](
