pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s

function sum(x, a, y) {
    return x + a[0] + a[1] + a[2] + a[3] + y;
}

template CallWithArray() {
    signal input x[4];
    signal output y;

    y <-- sum(77, x, 99);
}

component main = CallWithArray();

//CHECK-LABEL: define void @CallWithArray_{{[0-9]+}}_run
//CHECK-SAME: ([0 x i256]* %[[ARG:[0-9]+]])
//CHECK: call1:
//CHECK: %[[ARENA:sum_.*_arena]] = alloca [6 x i256]
//CHECK: %[[X_PTR:[0-9]+]] = getelementptr [6 x i256], [6 x i256]* %[[ARENA]], i32 0, i32 0
//CHECK: store i256 77, i256* %[[X_PTR]]
//CHECK: %[[DST:[0-9]+]] = getelementptr [6 x i256], [6 x i256]* %[[ARENA]], i32 0, i32 1
//CHECK: %[[SRC:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i32 1
//CHECK: call void @fr_copy_n(i256* %[[SRC]], i256* %[[DST]], i32 4)
//CHECK: %[[Y_PTR:[0-9]+]] = getelementptr [6 x i256], [6 x i256]* %[[ARENA]], i32 0, i32 5
//CHECK: store i256 99, i256* %[[Y_PTR]]
//CHECK: %[[ARENA_PTR:.*]] = bitcast [6 x i256]* %[[ARENA]] to i256*
//CHECK: %call.[[SUM:sum_[0-9]+]] = call i256 @[[SUM]](i256* %[[ARENA_PTR]])
//CHECK: %[[OUT:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i32 0
//CHECK: store i256 %call.[[SUM]], i256* %[[OUT]]
//CHECK: br label %prologue
