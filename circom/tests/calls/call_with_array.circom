pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s

function sum(a) {
    return a[0] + a[1] + a[2] + a[3];
}

template CallWithArray() {
    signal input x[4];
    signal output y;

    y <-- sum(x);
}

component main = CallWithArray();

//CHECK-LABEL: define{{.*}} void @fr_copy_n
//CHECK-SAME: (i256* %[[SRC:[0-9]+]], i256* %[[DST:[0-9]+]], i32 %[[LEN:[0-9]+]])
//CHECK: [[ENTRY_BB:.*]]:
//CHECK: %[[I:.*]] = alloca i32
//CHECK: store i32 0, i32* %[[I]]
//CHECK: br label %[[COND_BB:.*]]
//CHECK: [[COND_BB]]:
//CHECK-SAME: preds = %[[BODY_BB:.*]], %[[ENTRY_BB]]
//CHECK: %[[IDX:.*]] = load i32, i32* %[[I]]
//CHECK: %[[COND:.*]] = icmp slt i32 %[[IDX]], %[[LEN]]
//CHECK: br i1 %[[COND]], label %[[BODY_BB]], label %[[END_BB:.*]]
//CHECK: [[BODY_BB]]:
//CHECK-SAME: preds = %[[COND_BB]]
//CHECK: %[[CUR_IDX:.*]] = load i32, i32* %[[I]]
//CHECK: %[[SRC_PTR:.*]] = getelementptr i256, i256* %[[SRC]], i32 %[[CUR_IDX]]
//CHECK: %[[SRC_VAL:.*]] = load i256, i256* %[[SRC_PTR]]
//CHECK: %[[DST_PTR:.*]] = getelementptr i256, i256* %[[DST]], i32 %[[CUR_IDX]]
//CHECK: store i256 %[[SRC_VAL]], i256* %[[DST_PTR]]
//CHECK: %[[NXT_IDX:.*]] = add i32 %[[CUR_IDX]], 1
//CHECK: store i32 %[[NXT_IDX]], i32* %[[I]]
//CHECK: br label %[[COND_BB]]
//CHECK: [[END_BB]]:
//CHECK-SAME: preds = %[[COND_BB]]
//CHECK: ret void

//CHECK-LABEL: define{{.*}} void @CallWithArray_{{[0-9]+}}_run
//CHECK-SAME: ([0 x i256]* %[[ARG:[0-9]+]])
//CHECK: call1:
//CHECK: %[[ARENA:sum_.*_arena]] = alloca [4 x i256]
//CHECK: %[[DST:[0-9]+]] = getelementptr [4 x i256], [4 x i256]* %[[ARENA]], i32 0, i32 0
//CHECK: %[[SRC:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i32 1
//CHECK: call void @fr_copy_n(i256* %[[SRC]], i256* %[[DST]], i32 4)
//CHECK: %[[ARENA_PTR:.*]] = bitcast [4 x i256]* %[[ARENA]] to i256*
//CHECK: %call.[[SUM:sum_[0-9]+]] = call i256 @[[SUM]](i256* %[[ARENA_PTR]])
//CHECK: %[[OUT:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i32 0
//CHECK: store i256 %call.[[SUM]], i256* %[[OUT]]
//CHECK: br label %prologue