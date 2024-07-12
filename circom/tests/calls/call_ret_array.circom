pragma circom 2.1.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

function sum(a) {
    var b[4] = a;
    return b;
}

template CallRetTest() {
    signal input x[4];
    signal output y[4];

    y <-- sum(x);
}

component main = CallRetTest();

//CHECK-LABEL: define{{.*}} i256* @sum_
//CHECK-SAME: [[$F_ID_1:[0-9a-zA-Z_\.]+]](i256* %0){{.*}} {
//CHECK-NEXT: sum_[[$F_ID_1]]:
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY:
//CHECK-NEXT: store1:
//CHECK-NEXT:   %[[DST_PTR:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %0, i32 4
//CHECK-NEXT:   %[[SRC_PTR:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %0, i32 0
//CHECK-NEXT:   %[[CPY_SRC_0:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 0
//CHECK-NEXT:   %[[CPY_DST_0:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 0
//CHECK-NEXT:   %[[CPY_VAL_0:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_0]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_0]], i256* %[[CPY_DST_0]], align 4
//CHECK-NEXT:   %[[CPY_SRC_1:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 1
//CHECK-NEXT:   %[[CPY_DST_1:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 1
//CHECK-NEXT:   %[[CPY_VAL_1:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_1]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_1]], i256* %[[CPY_DST_1]], align 4
//CHECK-NEXT:   %[[CPY_SRC_2:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 2
//CHECK-NEXT:   %[[CPY_DST_2:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 2
//CHECK-NEXT:   %[[CPY_VAL_2:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_2]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_2]], i256* %[[CPY_DST_2]], align 4
//CHECK-NEXT:   %[[CPY_SRC_3:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 3
//CHECK-NEXT:   %[[CPY_DST_3:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 3
//CHECK-NEXT:   %[[CPY_VAL_3:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_3]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_3]], i256* %[[CPY_DST_3]], align 4
//CHECK-NEXT:   br label %return2
//CHECK-EMPTY:
//CHECK-NEXT: return2:
//CHECK-NEXT:   %[[T05:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %0, i32 4
//CHECK-NEXT:   ret i256* %[[T05]]
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @CallRetTest_0_run([0 x i256]* %0){{.*}} {
//CHECK-NEXT: prelude:
//CHECK-NEXT:   %lvars = alloca [0 x i256], align 8
//CHECK-NEXT:   %subcmps = alloca [0 x { [0 x i256]*, i32 }], align 8
//CHECK-NEXT:   br label %call1
//CHECK-EMPTY:
//CHECK-NEXT: call1:
//CHECK-NEXT:   %[[CALL_ARENA:[0-9a-zA-Z_\.]+]] = alloca [8 x i256], align 8
//CHECK-NEXT:   %[[DST_PTR:[0-9a-zA-Z_\.]+]] = getelementptr [8 x i256], [8 x i256]* %[[CALL_ARENA]], i32 0, i32 0
//CHECK-NEXT:   %[[SRC_PTR:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 4
//CHECK-NEXT:   %[[CPY_SRC_0:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 0
//CHECK-NEXT:   %[[CPY_DST_0:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 0
//CHECK-NEXT:   %[[CPY_VAL_0:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_0]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_0]], i256* %[[CPY_DST_0]], align 4
//CHECK-NEXT:   %[[CPY_SRC_1:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 1
//CHECK-NEXT:   %[[CPY_DST_1:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 1
//CHECK-NEXT:   %[[CPY_VAL_1:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_1]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_1]], i256* %[[CPY_DST_1]], align 4
//CHECK-NEXT:   %[[CPY_SRC_2:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 2
//CHECK-NEXT:   %[[CPY_DST_2:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 2
//CHECK-NEXT:   %[[CPY_VAL_2:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_2]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_2]], i256* %[[CPY_DST_2]], align 4
//CHECK-NEXT:   %[[CPY_SRC_3:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 3
//CHECK-NEXT:   %[[CPY_DST_3:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 3
//CHECK-NEXT:   %[[CPY_VAL_3:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_3]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_3]], i256* %[[CPY_DST_3]], align 4
//CHECK-NEXT:   %[[T03:[0-9a-zA-Z_\.]+]] = bitcast [8 x i256]* %[[CALL_ARENA]] to i256*
//CHECK-NEXT:   %[[SRC_PTR:[0-9a-zA-Z_\.]+]] = call i256* @sum_[[$F_ID_1]](i256* %[[T03]])
//CHECK-NEXT:   %[[DST_PTR:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 0
//CHECK-NEXT:   %[[CPY_SRC_01:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 0
//CHECK-NEXT:   %[[CPY_DST_02:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 0
//CHECK-NEXT:   %[[CPY_VAL_03:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_01]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_03]], i256* %[[CPY_DST_02]], align 4
//CHECK-NEXT:   %[[CPY_SRC_14:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 1
//CHECK-NEXT:   %[[CPY_DST_15:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 1
//CHECK-NEXT:   %[[CPY_VAL_16:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_14]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_16]], i256* %[[CPY_DST_15]], align 4
//CHECK-NEXT:   %[[CPY_SRC_27:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 2
//CHECK-NEXT:   %[[CPY_DST_28:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 2
//CHECK-NEXT:   %[[CPY_VAL_29:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_27]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_29]], i256* %[[CPY_DST_28]], align 4
//CHECK-NEXT:   %[[CPY_SRC_310:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 3
//CHECK-NEXT:   %[[CPY_DST_311:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 3
//CHECK-NEXT:   %[[CPY_VAL_312:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_310]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_312]], i256* %[[CPY_DST_311]], align 4
//CHECK-NEXT:   br label %prologue
//CHECK-EMPTY:
//CHECK-NEXT: prologue:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
