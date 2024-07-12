pragma circom 2.1.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

function sum(a) {
    var b[2][4][3] = a;
    return b;
}

template CallRetTest() {
    signal input x[2][4][3];
    signal output y[2][4][3];

    y <-- sum(x);
}

component main = CallRetTest();

//CHECK-LABEL: define{{.*}} i256* @sum_
//CHECK-SAME: [[$F_ID_1:[0-9a-zA-Z_\.]+]](i256* %0){{.*}} {
//CHECK-NEXT: sum_[[$F_ID_1]]:
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY:
//CHECK-NEXT: store1:
//CHECK-NEXT:   %[[DST_PTR:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %0, i32 24
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
//CHECK-NEXT:   %[[CPY_SRC_4:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 4
//CHECK-NEXT:   %[[CPY_DST_4:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 4
//CHECK-NEXT:   %[[CPY_VAL_4:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_4]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_4]], i256* %[[CPY_DST_4]], align 4
//CHECK-NEXT:   %[[CPY_SRC_5:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 5
//CHECK-NEXT:   %[[CPY_DST_5:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 5
//CHECK-NEXT:   %[[CPY_VAL_5:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_5]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_5]], i256* %[[CPY_DST_5]], align 4
//CHECK-NEXT:   %[[CPY_SRC_6:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 6
//CHECK-NEXT:   %[[CPY_DST_6:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 6
//CHECK-NEXT:   %[[CPY_VAL_6:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_6]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_6]], i256* %[[CPY_DST_6]], align 4
//CHECK-NEXT:   %[[CPY_SRC_7:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 7
//CHECK-NEXT:   %[[CPY_DST_7:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 7
//CHECK-NEXT:   %[[CPY_VAL_7:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_7]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_7]], i256* %[[CPY_DST_7]], align 4
//CHECK-NEXT:   %[[CPY_SRC_8:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 8
//CHECK-NEXT:   %[[CPY_DST_8:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 8
//CHECK-NEXT:   %[[CPY_VAL_8:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_8]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_8]], i256* %[[CPY_DST_8]], align 4
//CHECK-NEXT:   %[[CPY_SRC_9:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 9
//CHECK-NEXT:   %[[CPY_DST_9:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 9
//CHECK-NEXT:   %[[CPY_VAL_9:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_9]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_9]], i256* %[[CPY_DST_9]], align 4
//CHECK-NEXT:   %[[CPY_SRC_10:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 10
//CHECK-NEXT:   %[[CPY_DST_10:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 10
//CHECK-NEXT:   %[[CPY_VAL_10:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_10]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_10]], i256* %[[CPY_DST_10]], align 4
//CHECK-NEXT:   %[[CPY_SRC_11:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 11
//CHECK-NEXT:   %[[CPY_DST_11:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 11
//CHECK-NEXT:   %[[CPY_VAL_11:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_11]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_11]], i256* %[[CPY_DST_11]], align 4
//CHECK-NEXT:   %[[CPY_SRC_12:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 12
//CHECK-NEXT:   %[[CPY_DST_12:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 12
//CHECK-NEXT:   %[[CPY_VAL_12:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_12]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_12]], i256* %[[CPY_DST_12]], align 4
//CHECK-NEXT:   %[[CPY_SRC_13:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 13
//CHECK-NEXT:   %[[CPY_DST_13:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 13
//CHECK-NEXT:   %[[CPY_VAL_13:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_13]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_13]], i256* %[[CPY_DST_13]], align 4
//CHECK-NEXT:   %[[CPY_SRC_14:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 14
//CHECK-NEXT:   %[[CPY_DST_14:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 14
//CHECK-NEXT:   %[[CPY_VAL_14:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_14]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_14]], i256* %[[CPY_DST_14]], align 4
//CHECK-NEXT:   %[[CPY_SRC_15:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 15
//CHECK-NEXT:   %[[CPY_DST_15:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 15
//CHECK-NEXT:   %[[CPY_VAL_15:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_15]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_15]], i256* %[[CPY_DST_15]], align 4
//CHECK-NEXT:   %[[CPY_SRC_16:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 16
//CHECK-NEXT:   %[[CPY_DST_16:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 16
//CHECK-NEXT:   %[[CPY_VAL_16:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_16]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_16]], i256* %[[CPY_DST_16]], align 4
//CHECK-NEXT:   %[[CPY_SRC_17:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 17
//CHECK-NEXT:   %[[CPY_DST_17:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 17
//CHECK-NEXT:   %[[CPY_VAL_17:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_17]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_17]], i256* %[[CPY_DST_17]], align 4
//CHECK-NEXT:   %[[CPY_SRC_18:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 18
//CHECK-NEXT:   %[[CPY_DST_18:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 18
//CHECK-NEXT:   %[[CPY_VAL_18:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_18]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_18]], i256* %[[CPY_DST_18]], align 4
//CHECK-NEXT:   %[[CPY_SRC_19:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 19
//CHECK-NEXT:   %[[CPY_DST_19:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 19
//CHECK-NEXT:   %[[CPY_VAL_19:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_19]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_19]], i256* %[[CPY_DST_19]], align 4
//CHECK-NEXT:   %[[CPY_SRC_20:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 20
//CHECK-NEXT:   %[[CPY_DST_20:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 20
//CHECK-NEXT:   %[[CPY_VAL_20:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_20]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_20]], i256* %[[CPY_DST_20]], align 4
//CHECK-NEXT:   %[[CPY_SRC_21:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 21
//CHECK-NEXT:   %[[CPY_DST_21:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 21
//CHECK-NEXT:   %[[CPY_VAL_21:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_21]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_21]], i256* %[[CPY_DST_21]], align 4
//CHECK-NEXT:   %[[CPY_SRC_22:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 22
//CHECK-NEXT:   %[[CPY_DST_22:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 22
//CHECK-NEXT:   %[[CPY_VAL_22:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_22]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_22]], i256* %[[CPY_DST_22]], align 4
//CHECK-NEXT:   %[[CPY_SRC_23:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 23
//CHECK-NEXT:   %[[CPY_DST_23:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 23
//CHECK-NEXT:   %[[CPY_VAL_23:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_23]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_23]], i256* %[[CPY_DST_23]], align 4
//CHECK-NEXT:   br label %return2
//CHECK-EMPTY:
//CHECK-NEXT: return2:
//CHECK-NEXT:   %[[T05:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %0, i32 24
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
//CHECK-NEXT:   %[[CALL_ARENA:[0-9a-zA-Z_\.]+]] = alloca [48 x i256], align 8
//CHECK-NEXT:   %[[DST_PTR:[0-9a-zA-Z_\.]+]] = getelementptr [48 x i256], [48 x i256]* %[[CALL_ARENA]], i32 0, i32 0
//CHECK-NEXT:   %[[SRC_PTR:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 24
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
//CHECK-NEXT:   %[[CPY_SRC_4:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 4
//CHECK-NEXT:   %[[CPY_DST_4:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 4
//CHECK-NEXT:   %[[CPY_VAL_4:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_4]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_4]], i256* %[[CPY_DST_4]], align 4
//CHECK-NEXT:   %[[CPY_SRC_5:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 5
//CHECK-NEXT:   %[[CPY_DST_5:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 5
//CHECK-NEXT:   %[[CPY_VAL_5:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_5]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_5]], i256* %[[CPY_DST_5]], align 4
//CHECK-NEXT:   %[[CPY_SRC_6:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 6
//CHECK-NEXT:   %[[CPY_DST_6:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 6
//CHECK-NEXT:   %[[CPY_VAL_6:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_6]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_6]], i256* %[[CPY_DST_6]], align 4
//CHECK-NEXT:   %[[CPY_SRC_7:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 7
//CHECK-NEXT:   %[[CPY_DST_7:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 7
//CHECK-NEXT:   %[[CPY_VAL_7:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_7]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_7]], i256* %[[CPY_DST_7]], align 4
//CHECK-NEXT:   %[[CPY_SRC_8:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 8
//CHECK-NEXT:   %[[CPY_DST_8:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 8
//CHECK-NEXT:   %[[CPY_VAL_8:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_8]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_8]], i256* %[[CPY_DST_8]], align 4
//CHECK-NEXT:   %[[CPY_SRC_9:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 9
//CHECK-NEXT:   %[[CPY_DST_9:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 9
//CHECK-NEXT:   %[[CPY_VAL_9:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_9]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_9]], i256* %[[CPY_DST_9]], align 4
//CHECK-NEXT:   %[[CPY_SRC_10:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 10
//CHECK-NEXT:   %[[CPY_DST_10:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 10
//CHECK-NEXT:   %[[CPY_VAL_10:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_10]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_10]], i256* %[[CPY_DST_10]], align 4
//CHECK-NEXT:   %[[CPY_SRC_11:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 11
//CHECK-NEXT:   %[[CPY_DST_11:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 11
//CHECK-NEXT:   %[[CPY_VAL_11:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_11]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_11]], i256* %[[CPY_DST_11]], align 4
//CHECK-NEXT:   %[[CPY_SRC_12:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 12
//CHECK-NEXT:   %[[CPY_DST_12:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 12
//CHECK-NEXT:   %[[CPY_VAL_12:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_12]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_12]], i256* %[[CPY_DST_12]], align 4
//CHECK-NEXT:   %[[CPY_SRC_13:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 13
//CHECK-NEXT:   %[[CPY_DST_13:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 13
//CHECK-NEXT:   %[[CPY_VAL_13:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_13]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_13]], i256* %[[CPY_DST_13]], align 4
//CHECK-NEXT:   %[[CPY_SRC_14:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 14
//CHECK-NEXT:   %[[CPY_DST_14:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 14
//CHECK-NEXT:   %[[CPY_VAL_14:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_14]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_14]], i256* %[[CPY_DST_14]], align 4
//CHECK-NEXT:   %[[CPY_SRC_15:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 15
//CHECK-NEXT:   %[[CPY_DST_15:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 15
//CHECK-NEXT:   %[[CPY_VAL_15:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_15]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_15]], i256* %[[CPY_DST_15]], align 4
//CHECK-NEXT:   %[[CPY_SRC_16:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 16
//CHECK-NEXT:   %[[CPY_DST_16:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 16
//CHECK-NEXT:   %[[CPY_VAL_16:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_16]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_16]], i256* %[[CPY_DST_16]], align 4
//CHECK-NEXT:   %[[CPY_SRC_17:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 17
//CHECK-NEXT:   %[[CPY_DST_17:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 17
//CHECK-NEXT:   %[[CPY_VAL_17:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_17]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_17]], i256* %[[CPY_DST_17]], align 4
//CHECK-NEXT:   %[[CPY_SRC_18:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 18
//CHECK-NEXT:   %[[CPY_DST_18:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 18
//CHECK-NEXT:   %[[CPY_VAL_18:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_18]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_18]], i256* %[[CPY_DST_18]], align 4
//CHECK-NEXT:   %[[CPY_SRC_19:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 19
//CHECK-NEXT:   %[[CPY_DST_19:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 19
//CHECK-NEXT:   %[[CPY_VAL_19:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_19]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_19]], i256* %[[CPY_DST_19]], align 4
//CHECK-NEXT:   %[[CPY_SRC_20:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 20
//CHECK-NEXT:   %[[CPY_DST_20:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 20
//CHECK-NEXT:   %[[CPY_VAL_20:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_20]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_20]], i256* %[[CPY_DST_20]], align 4
//CHECK-NEXT:   %[[CPY_SRC_21:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 21
//CHECK-NEXT:   %[[CPY_DST_21:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 21
//CHECK-NEXT:   %[[CPY_VAL_21:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_21]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_21]], i256* %[[CPY_DST_21]], align 4
//CHECK-NEXT:   %[[CPY_SRC_22:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 22
//CHECK-NEXT:   %[[CPY_DST_22:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 22
//CHECK-NEXT:   %[[CPY_VAL_22:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_22]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_22]], i256* %[[CPY_DST_22]], align 4
//CHECK-NEXT:   %[[CPY_SRC_23:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 23
//CHECK-NEXT:   %[[CPY_DST_23:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 23
//CHECK-NEXT:   %[[CPY_VAL_23:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_23]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_23]], i256* %[[CPY_DST_23]], align 4
//CHECK-NEXT:   %[[T03:[0-9a-zA-Z_\.]+]] = bitcast [48 x i256]* %[[CALL_ARENA]] to i256*
//CHECK-NEXT:   %[[SRC_PTR:[0-9a-zA-Z_\.]+]] = call i256* @sum_[[$F_ID_1]](i256* %[[T03]])
//CHECK-NEXT:   %[[DST_PTR:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 0
//CHECK-NEXT:   %[[CPY_SRC_01:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 0
//CHECK-NEXT:   %[[CPY_DST_02:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 0
//CHECK-NEXT:   %[[CPY_VAL_03:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_01]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_03]], i256* %[[CPY_DST_02]], align 4
//CHECK-NEXT:   %[[CPY_SRC_110:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 1
//CHECK-NEXT:   %[[CPY_DST_111:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 1
//CHECK-NEXT:   %[[CPY_VAL_112:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_110]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_112]], i256* %[[CPY_DST_111]], align 4
//CHECK-NEXT:   %[[CPY_SRC_213:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 2
//CHECK-NEXT:   %[[CPY_DST_214:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 2
//CHECK-NEXT:   %[[CPY_VAL_215:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_213]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_215]], i256* %[[CPY_DST_214]], align 4
//CHECK-NEXT:   %[[CPY_SRC_316:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 3
//CHECK-NEXT:   %[[CPY_DST_317:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 3
//CHECK-NEXT:   %[[CPY_VAL_318:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_316]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_318]], i256* %[[CPY_DST_317]], align 4
//CHECK-NEXT:   %[[CPY_SRC_419:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 4
//CHECK-NEXT:   %[[CPY_DST_420:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 4
//CHECK-NEXT:   %[[CPY_VAL_421:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_419]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_421]], i256* %[[CPY_DST_420]], align 4
//CHECK-NEXT:   %[[CPY_SRC_522:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 5
//CHECK-NEXT:   %[[CPY_DST_523:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 5
//CHECK-NEXT:   %[[CPY_VAL_524:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_522]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_524]], i256* %[[CPY_DST_523]], align 4
//CHECK-NEXT:   %[[CPY_SRC_625:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 6
//CHECK-NEXT:   %[[CPY_DST_626:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 6
//CHECK-NEXT:   %[[CPY_VAL_627:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_625]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_627]], i256* %[[CPY_DST_626]], align 4
//CHECK-NEXT:   %[[CPY_SRC_728:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 7
//CHECK-NEXT:   %[[CPY_DST_729:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 7
//CHECK-NEXT:   %[[CPY_VAL_730:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_728]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_730]], i256* %[[CPY_DST_729]], align 4
//CHECK-NEXT:   %[[CPY_SRC_831:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 8
//CHECK-NEXT:   %[[CPY_DST_832:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 8
//CHECK-NEXT:   %[[CPY_VAL_833:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_831]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_833]], i256* %[[CPY_DST_832]], align 4
//CHECK-NEXT:   %[[CPY_SRC_934:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 9
//CHECK-NEXT:   %[[CPY_DST_935:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 9
//CHECK-NEXT:   %[[CPY_VAL_936:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_934]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_936]], i256* %[[CPY_DST_935]], align 4
//CHECK-NEXT:   %[[CPY_SRC_1037:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 10
//CHECK-NEXT:   %[[CPY_DST_1038:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 10
//CHECK-NEXT:   %[[CPY_VAL_1039:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_1037]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_1039]], i256* %[[CPY_DST_1038]], align 4
//CHECK-NEXT:   %[[CPY_SRC_1140:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 11
//CHECK-NEXT:   %[[CPY_DST_1141:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 11
//CHECK-NEXT:   %[[CPY_VAL_1142:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_1140]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_1142]], i256* %[[CPY_DST_1141]], align 4
//CHECK-NEXT:   %[[CPY_SRC_1243:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 12
//CHECK-NEXT:   %[[CPY_DST_1244:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 12
//CHECK-NEXT:   %[[CPY_VAL_1245:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_1243]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_1245]], i256* %[[CPY_DST_1244]], align 4
//CHECK-NEXT:   %[[CPY_SRC_1346:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 13
//CHECK-NEXT:   %[[CPY_DST_1347:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 13
//CHECK-NEXT:   %[[CPY_VAL_1348:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_1346]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_1348]], i256* %[[CPY_DST_1347]], align 4
//CHECK-NEXT:   %[[CPY_SRC_1449:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 14
//CHECK-NEXT:   %[[CPY_DST_1450:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 14
//CHECK-NEXT:   %[[CPY_VAL_1451:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_1449]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_1451]], i256* %[[CPY_DST_1450]], align 4
//CHECK-NEXT:   %[[CPY_SRC_1552:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 15
//CHECK-NEXT:   %[[CPY_DST_1553:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 15
//CHECK-NEXT:   %[[CPY_VAL_1554:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_1552]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_1554]], i256* %[[CPY_DST_1553]], align 4
//CHECK-NEXT:   %[[CPY_SRC_1655:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 16
//CHECK-NEXT:   %[[CPY_DST_1656:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 16
//CHECK-NEXT:   %[[CPY_VAL_1657:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_1655]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_1657]], i256* %[[CPY_DST_1656]], align 4
//CHECK-NEXT:   %[[CPY_SRC_1758:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 17
//CHECK-NEXT:   %[[CPY_DST_1759:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 17
//CHECK-NEXT:   %[[CPY_VAL_1760:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_1758]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_1760]], i256* %[[CPY_DST_1759]], align 4
//CHECK-NEXT:   %[[CPY_SRC_1861:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 18
//CHECK-NEXT:   %[[CPY_DST_1862:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 18
//CHECK-NEXT:   %[[CPY_VAL_1863:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_1861]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_1863]], i256* %[[CPY_DST_1862]], align 4
//CHECK-NEXT:   %[[CPY_SRC_1964:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 19
//CHECK-NEXT:   %[[CPY_DST_1965:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 19
//CHECK-NEXT:   %[[CPY_VAL_1966:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_1964]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_1966]], i256* %[[CPY_DST_1965]], align 4
//CHECK-NEXT:   %[[CPY_SRC_2067:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 20
//CHECK-NEXT:   %[[CPY_DST_2068:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 20
//CHECK-NEXT:   %[[CPY_VAL_2069:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_2067]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_2069]], i256* %[[CPY_DST_2068]], align 4
//CHECK-NEXT:   %[[CPY_SRC_2170:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 21
//CHECK-NEXT:   %[[CPY_DST_2171:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 21
//CHECK-NEXT:   %[[CPY_VAL_2172:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_2170]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_2172]], i256* %[[CPY_DST_2171]], align 4
//CHECK-NEXT:   %[[CPY_SRC_2273:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 22
//CHECK-NEXT:   %[[CPY_DST_2274:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 22
//CHECK-NEXT:   %[[CPY_VAL_2275:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_2273]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_2275]], i256* %[[CPY_DST_2274]], align 4
//CHECK-NEXT:   %[[CPY_SRC_2376:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 23
//CHECK-NEXT:   %[[CPY_DST_2377:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 23
//CHECK-NEXT:   %[[CPY_VAL_2378:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[CPY_SRC_2376]], align 4
//CHECK-NEXT:   store i256 %[[CPY_VAL_2378]], i256* %[[CPY_DST_2377]], align 4
//CHECK-NEXT:   br label %prologue
