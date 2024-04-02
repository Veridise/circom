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

//CHECK-LABEL: define{{.*}} i256* @sum_0(i256* %0){{.*}} {
//CHECK-NEXT: sum_0:
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY:
//CHECK-NEXT: store1:
//CHECK-NEXT:   %[[DST_PTR:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %0, i32 24
//CHECK-NEXT:   %[[SRC_PTR:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %0, i32 0
//CHECK-NEXT:   %copy_src_0 = getelementptr i256, i256* %[[SRC_PTR]], i32 0
//CHECK-NEXT:   %copy_dst_0 = getelementptr i256, i256* %[[DST_PTR]], i32 0
//CHECK-NEXT:   %copy_val_0 = load i256, i256* %copy_src_0, align 4
//CHECK-NEXT:   store i256 %copy_val_0, i256* %copy_dst_0, align 4
//CHECK-NEXT:   %copy_src_1 = getelementptr i256, i256* %[[SRC_PTR]], i32 1
//CHECK-NEXT:   %copy_dst_1 = getelementptr i256, i256* %[[DST_PTR]], i32 1
//CHECK-NEXT:   %copy_val_1 = load i256, i256* %copy_src_1, align 4
//CHECK-NEXT:   store i256 %copy_val_1, i256* %copy_dst_1, align 4
//CHECK-NEXT:   %copy_src_2 = getelementptr i256, i256* %[[SRC_PTR]], i32 2
//CHECK-NEXT:   %copy_dst_2 = getelementptr i256, i256* %[[DST_PTR]], i32 2
//CHECK-NEXT:   %copy_val_2 = load i256, i256* %copy_src_2, align 4
//CHECK-NEXT:   store i256 %copy_val_2, i256* %copy_dst_2, align 4
//CHECK-NEXT:   %copy_src_3 = getelementptr i256, i256* %[[SRC_PTR]], i32 3
//CHECK-NEXT:   %copy_dst_3 = getelementptr i256, i256* %[[DST_PTR]], i32 3
//CHECK-NEXT:   %copy_val_3 = load i256, i256* %copy_src_3, align 4
//CHECK-NEXT:   store i256 %copy_val_3, i256* %copy_dst_3, align 4
//CHECK-NEXT:   %copy_src_4 = getelementptr i256, i256* %[[SRC_PTR]], i32 4
//CHECK-NEXT:   %copy_dst_4 = getelementptr i256, i256* %[[DST_PTR]], i32 4
//CHECK-NEXT:   %copy_val_4 = load i256, i256* %copy_src_4, align 4
//CHECK-NEXT:   store i256 %copy_val_4, i256* %copy_dst_4, align 4
//CHECK-NEXT:   %copy_src_5 = getelementptr i256, i256* %[[SRC_PTR]], i32 5
//CHECK-NEXT:   %copy_dst_5 = getelementptr i256, i256* %[[DST_PTR]], i32 5
//CHECK-NEXT:   %copy_val_5 = load i256, i256* %copy_src_5, align 4
//CHECK-NEXT:   store i256 %copy_val_5, i256* %copy_dst_5, align 4
//CHECK-NEXT:   %copy_src_6 = getelementptr i256, i256* %[[SRC_PTR]], i32 6
//CHECK-NEXT:   %copy_dst_6 = getelementptr i256, i256* %[[DST_PTR]], i32 6
//CHECK-NEXT:   %copy_val_6 = load i256, i256* %copy_src_6, align 4
//CHECK-NEXT:   store i256 %copy_val_6, i256* %copy_dst_6, align 4
//CHECK-NEXT:   %copy_src_7 = getelementptr i256, i256* %[[SRC_PTR]], i32 7
//CHECK-NEXT:   %copy_dst_7 = getelementptr i256, i256* %[[DST_PTR]], i32 7
//CHECK-NEXT:   %copy_val_7 = load i256, i256* %copy_src_7, align 4
//CHECK-NEXT:   store i256 %copy_val_7, i256* %copy_dst_7, align 4
//CHECK-NEXT:   %copy_src_8 = getelementptr i256, i256* %[[SRC_PTR]], i32 8
//CHECK-NEXT:   %copy_dst_8 = getelementptr i256, i256* %[[DST_PTR]], i32 8
//CHECK-NEXT:   %copy_val_8 = load i256, i256* %copy_src_8, align 4
//CHECK-NEXT:   store i256 %copy_val_8, i256* %copy_dst_8, align 4
//CHECK-NEXT:   %copy_src_9 = getelementptr i256, i256* %[[SRC_PTR]], i32 9
//CHECK-NEXT:   %copy_dst_9 = getelementptr i256, i256* %[[DST_PTR]], i32 9
//CHECK-NEXT:   %copy_val_9 = load i256, i256* %copy_src_9, align 4
//CHECK-NEXT:   store i256 %copy_val_9, i256* %copy_dst_9, align 4
//CHECK-NEXT:   %copy_src_10 = getelementptr i256, i256* %[[SRC_PTR]], i32 10
//CHECK-NEXT:   %copy_dst_10 = getelementptr i256, i256* %[[DST_PTR]], i32 10
//CHECK-NEXT:   %copy_val_10 = load i256, i256* %copy_src_10, align 4
//CHECK-NEXT:   store i256 %copy_val_10, i256* %copy_dst_10, align 4
//CHECK-NEXT:   %copy_src_11 = getelementptr i256, i256* %[[SRC_PTR]], i32 11
//CHECK-NEXT:   %copy_dst_11 = getelementptr i256, i256* %[[DST_PTR]], i32 11
//CHECK-NEXT:   %copy_val_11 = load i256, i256* %copy_src_11, align 4
//CHECK-NEXT:   store i256 %copy_val_11, i256* %copy_dst_11, align 4
//CHECK-NEXT:   %copy_src_12 = getelementptr i256, i256* %[[SRC_PTR]], i32 12
//CHECK-NEXT:   %copy_dst_12 = getelementptr i256, i256* %[[DST_PTR]], i32 12
//CHECK-NEXT:   %copy_val_12 = load i256, i256* %copy_src_12, align 4
//CHECK-NEXT:   store i256 %copy_val_12, i256* %copy_dst_12, align 4
//CHECK-NEXT:   %copy_src_13 = getelementptr i256, i256* %[[SRC_PTR]], i32 13
//CHECK-NEXT:   %copy_dst_13 = getelementptr i256, i256* %[[DST_PTR]], i32 13
//CHECK-NEXT:   %copy_val_13 = load i256, i256* %copy_src_13, align 4
//CHECK-NEXT:   store i256 %copy_val_13, i256* %copy_dst_13, align 4
//CHECK-NEXT:   %copy_src_14 = getelementptr i256, i256* %[[SRC_PTR]], i32 14
//CHECK-NEXT:   %copy_dst_14 = getelementptr i256, i256* %[[DST_PTR]], i32 14
//CHECK-NEXT:   %copy_val_14 = load i256, i256* %copy_src_14, align 4
//CHECK-NEXT:   store i256 %copy_val_14, i256* %copy_dst_14, align 4
//CHECK-NEXT:   %copy_src_15 = getelementptr i256, i256* %[[SRC_PTR]], i32 15
//CHECK-NEXT:   %copy_dst_15 = getelementptr i256, i256* %[[DST_PTR]], i32 15
//CHECK-NEXT:   %copy_val_15 = load i256, i256* %copy_src_15, align 4
//CHECK-NEXT:   store i256 %copy_val_15, i256* %copy_dst_15, align 4
//CHECK-NEXT:   %copy_src_16 = getelementptr i256, i256* %[[SRC_PTR]], i32 16
//CHECK-NEXT:   %copy_dst_16 = getelementptr i256, i256* %[[DST_PTR]], i32 16
//CHECK-NEXT:   %copy_val_16 = load i256, i256* %copy_src_16, align 4
//CHECK-NEXT:   store i256 %copy_val_16, i256* %copy_dst_16, align 4
//CHECK-NEXT:   %copy_src_17 = getelementptr i256, i256* %[[SRC_PTR]], i32 17
//CHECK-NEXT:   %copy_dst_17 = getelementptr i256, i256* %[[DST_PTR]], i32 17
//CHECK-NEXT:   %copy_val_17 = load i256, i256* %copy_src_17, align 4
//CHECK-NEXT:   store i256 %copy_val_17, i256* %copy_dst_17, align 4
//CHECK-NEXT:   %copy_src_18 = getelementptr i256, i256* %[[SRC_PTR]], i32 18
//CHECK-NEXT:   %copy_dst_18 = getelementptr i256, i256* %[[DST_PTR]], i32 18
//CHECK-NEXT:   %copy_val_18 = load i256, i256* %copy_src_18, align 4
//CHECK-NEXT:   store i256 %copy_val_18, i256* %copy_dst_18, align 4
//CHECK-NEXT:   %copy_src_19 = getelementptr i256, i256* %[[SRC_PTR]], i32 19
//CHECK-NEXT:   %copy_dst_19 = getelementptr i256, i256* %[[DST_PTR]], i32 19
//CHECK-NEXT:   %copy_val_19 = load i256, i256* %copy_src_19, align 4
//CHECK-NEXT:   store i256 %copy_val_19, i256* %copy_dst_19, align 4
//CHECK-NEXT:   %copy_src_20 = getelementptr i256, i256* %[[SRC_PTR]], i32 20
//CHECK-NEXT:   %copy_dst_20 = getelementptr i256, i256* %[[DST_PTR]], i32 20
//CHECK-NEXT:   %copy_val_20 = load i256, i256* %copy_src_20, align 4
//CHECK-NEXT:   store i256 %copy_val_20, i256* %copy_dst_20, align 4
//CHECK-NEXT:   %copy_src_21 = getelementptr i256, i256* %[[SRC_PTR]], i32 21
//CHECK-NEXT:   %copy_dst_21 = getelementptr i256, i256* %[[DST_PTR]], i32 21
//CHECK-NEXT:   %copy_val_21 = load i256, i256* %copy_src_21, align 4
//CHECK-NEXT:   store i256 %copy_val_21, i256* %copy_dst_21, align 4
//CHECK-NEXT:   %copy_src_22 = getelementptr i256, i256* %[[SRC_PTR]], i32 22
//CHECK-NEXT:   %copy_dst_22 = getelementptr i256, i256* %[[DST_PTR]], i32 22
//CHECK-NEXT:   %copy_val_22 = load i256, i256* %copy_src_22, align 4
//CHECK-NEXT:   store i256 %copy_val_22, i256* %copy_dst_22, align 4
//CHECK-NEXT:   %copy_src_23 = getelementptr i256, i256* %[[SRC_PTR]], i32 23
//CHECK-NEXT:   %copy_dst_23 = getelementptr i256, i256* %[[DST_PTR]], i32 23
//CHECK-NEXT:   %copy_val_23 = load i256, i256* %copy_src_23, align 4
//CHECK-NEXT:   store i256 %copy_val_23, i256* %copy_dst_23, align 4
//CHECK-NEXT:   br label %return2
//CHECK-EMPTY:
//CHECK-NEXT: return2:
//CHECK-NEXT:   %[[T05:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %0, i32 24
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
//CHECK-NEXT:   %sum_0_arena = alloca [48 x i256], align 8
//CHECK-NEXT:   %[[DST_PTR:[0-9a-zA-Z_.]+]] = getelementptr [48 x i256], [48 x i256]* %sum_0_arena, i32 0, i32 0
//CHECK-NEXT:   %[[SRC_PTR:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 24
//CHECK-NEXT:   %copy_src_0 = getelementptr i256, i256* %[[SRC_PTR]], i32 0
//CHECK-NEXT:   %copy_dst_0 = getelementptr i256, i256* %[[DST_PTR]], i32 0
//CHECK-NEXT:   %copy_val_0 = load i256, i256* %copy_src_0, align 4
//CHECK-NEXT:   store i256 %copy_val_0, i256* %copy_dst_0, align 4
//CHECK-NEXT:   %copy_src_1 = getelementptr i256, i256* %[[SRC_PTR]], i32 1
//CHECK-NEXT:   %copy_dst_1 = getelementptr i256, i256* %[[DST_PTR]], i32 1
//CHECK-NEXT:   %copy_val_1 = load i256, i256* %copy_src_1, align 4
//CHECK-NEXT:   store i256 %copy_val_1, i256* %copy_dst_1, align 4
//CHECK-NEXT:   %copy_src_2 = getelementptr i256, i256* %[[SRC_PTR]], i32 2
//CHECK-NEXT:   %copy_dst_2 = getelementptr i256, i256* %[[DST_PTR]], i32 2
//CHECK-NEXT:   %copy_val_2 = load i256, i256* %copy_src_2, align 4
//CHECK-NEXT:   store i256 %copy_val_2, i256* %copy_dst_2, align 4
//CHECK-NEXT:   %copy_src_3 = getelementptr i256, i256* %[[SRC_PTR]], i32 3
//CHECK-NEXT:   %copy_dst_3 = getelementptr i256, i256* %[[DST_PTR]], i32 3
//CHECK-NEXT:   %copy_val_3 = load i256, i256* %copy_src_3, align 4
//CHECK-NEXT:   store i256 %copy_val_3, i256* %copy_dst_3, align 4
//CHECK-NEXT:   %copy_src_4 = getelementptr i256, i256* %[[SRC_PTR]], i32 4
//CHECK-NEXT:   %copy_dst_4 = getelementptr i256, i256* %[[DST_PTR]], i32 4
//CHECK-NEXT:   %copy_val_4 = load i256, i256* %copy_src_4, align 4
//CHECK-NEXT:   store i256 %copy_val_4, i256* %copy_dst_4, align 4
//CHECK-NEXT:   %copy_src_5 = getelementptr i256, i256* %[[SRC_PTR]], i32 5
//CHECK-NEXT:   %copy_dst_5 = getelementptr i256, i256* %[[DST_PTR]], i32 5
//CHECK-NEXT:   %copy_val_5 = load i256, i256* %copy_src_5, align 4
//CHECK-NEXT:   store i256 %copy_val_5, i256* %copy_dst_5, align 4
//CHECK-NEXT:   %copy_src_6 = getelementptr i256, i256* %[[SRC_PTR]], i32 6
//CHECK-NEXT:   %copy_dst_6 = getelementptr i256, i256* %[[DST_PTR]], i32 6
//CHECK-NEXT:   %copy_val_6 = load i256, i256* %copy_src_6, align 4
//CHECK-NEXT:   store i256 %copy_val_6, i256* %copy_dst_6, align 4
//CHECK-NEXT:   %copy_src_7 = getelementptr i256, i256* %[[SRC_PTR]], i32 7
//CHECK-NEXT:   %copy_dst_7 = getelementptr i256, i256* %[[DST_PTR]], i32 7
//CHECK-NEXT:   %copy_val_7 = load i256, i256* %copy_src_7, align 4
//CHECK-NEXT:   store i256 %copy_val_7, i256* %copy_dst_7, align 4
//CHECK-NEXT:   %copy_src_8 = getelementptr i256, i256* %[[SRC_PTR]], i32 8
//CHECK-NEXT:   %copy_dst_8 = getelementptr i256, i256* %[[DST_PTR]], i32 8
//CHECK-NEXT:   %copy_val_8 = load i256, i256* %copy_src_8, align 4
//CHECK-NEXT:   store i256 %copy_val_8, i256* %copy_dst_8, align 4
//CHECK-NEXT:   %copy_src_9 = getelementptr i256, i256* %[[SRC_PTR]], i32 9
//CHECK-NEXT:   %copy_dst_9 = getelementptr i256, i256* %[[DST_PTR]], i32 9
//CHECK-NEXT:   %copy_val_9 = load i256, i256* %copy_src_9, align 4
//CHECK-NEXT:   store i256 %copy_val_9, i256* %copy_dst_9, align 4
//CHECK-NEXT:   %copy_src_10 = getelementptr i256, i256* %[[SRC_PTR]], i32 10
//CHECK-NEXT:   %copy_dst_10 = getelementptr i256, i256* %[[DST_PTR]], i32 10
//CHECK-NEXT:   %copy_val_10 = load i256, i256* %copy_src_10, align 4
//CHECK-NEXT:   store i256 %copy_val_10, i256* %copy_dst_10, align 4
//CHECK-NEXT:   %copy_src_11 = getelementptr i256, i256* %[[SRC_PTR]], i32 11
//CHECK-NEXT:   %copy_dst_11 = getelementptr i256, i256* %[[DST_PTR]], i32 11
//CHECK-NEXT:   %copy_val_11 = load i256, i256* %copy_src_11, align 4
//CHECK-NEXT:   store i256 %copy_val_11, i256* %copy_dst_11, align 4
//CHECK-NEXT:   %copy_src_12 = getelementptr i256, i256* %[[SRC_PTR]], i32 12
//CHECK-NEXT:   %copy_dst_12 = getelementptr i256, i256* %[[DST_PTR]], i32 12
//CHECK-NEXT:   %copy_val_12 = load i256, i256* %copy_src_12, align 4
//CHECK-NEXT:   store i256 %copy_val_12, i256* %copy_dst_12, align 4
//CHECK-NEXT:   %copy_src_13 = getelementptr i256, i256* %[[SRC_PTR]], i32 13
//CHECK-NEXT:   %copy_dst_13 = getelementptr i256, i256* %[[DST_PTR]], i32 13
//CHECK-NEXT:   %copy_val_13 = load i256, i256* %copy_src_13, align 4
//CHECK-NEXT:   store i256 %copy_val_13, i256* %copy_dst_13, align 4
//CHECK-NEXT:   %copy_src_14 = getelementptr i256, i256* %[[SRC_PTR]], i32 14
//CHECK-NEXT:   %copy_dst_14 = getelementptr i256, i256* %[[DST_PTR]], i32 14
//CHECK-NEXT:   %copy_val_14 = load i256, i256* %copy_src_14, align 4
//CHECK-NEXT:   store i256 %copy_val_14, i256* %copy_dst_14, align 4
//CHECK-NEXT:   %copy_src_15 = getelementptr i256, i256* %[[SRC_PTR]], i32 15
//CHECK-NEXT:   %copy_dst_15 = getelementptr i256, i256* %[[DST_PTR]], i32 15
//CHECK-NEXT:   %copy_val_15 = load i256, i256* %copy_src_15, align 4
//CHECK-NEXT:   store i256 %copy_val_15, i256* %copy_dst_15, align 4
//CHECK-NEXT:   %copy_src_16 = getelementptr i256, i256* %[[SRC_PTR]], i32 16
//CHECK-NEXT:   %copy_dst_16 = getelementptr i256, i256* %[[DST_PTR]], i32 16
//CHECK-NEXT:   %copy_val_16 = load i256, i256* %copy_src_16, align 4
//CHECK-NEXT:   store i256 %copy_val_16, i256* %copy_dst_16, align 4
//CHECK-NEXT:   %copy_src_17 = getelementptr i256, i256* %[[SRC_PTR]], i32 17
//CHECK-NEXT:   %copy_dst_17 = getelementptr i256, i256* %[[DST_PTR]], i32 17
//CHECK-NEXT:   %copy_val_17 = load i256, i256* %copy_src_17, align 4
//CHECK-NEXT:   store i256 %copy_val_17, i256* %copy_dst_17, align 4
//CHECK-NEXT:   %copy_src_18 = getelementptr i256, i256* %[[SRC_PTR]], i32 18
//CHECK-NEXT:   %copy_dst_18 = getelementptr i256, i256* %[[DST_PTR]], i32 18
//CHECK-NEXT:   %copy_val_18 = load i256, i256* %copy_src_18, align 4
//CHECK-NEXT:   store i256 %copy_val_18, i256* %copy_dst_18, align 4
//CHECK-NEXT:   %copy_src_19 = getelementptr i256, i256* %[[SRC_PTR]], i32 19
//CHECK-NEXT:   %copy_dst_19 = getelementptr i256, i256* %[[DST_PTR]], i32 19
//CHECK-NEXT:   %copy_val_19 = load i256, i256* %copy_src_19, align 4
//CHECK-NEXT:   store i256 %copy_val_19, i256* %copy_dst_19, align 4
//CHECK-NEXT:   %copy_src_20 = getelementptr i256, i256* %[[SRC_PTR]], i32 20
//CHECK-NEXT:   %copy_dst_20 = getelementptr i256, i256* %[[DST_PTR]], i32 20
//CHECK-NEXT:   %copy_val_20 = load i256, i256* %copy_src_20, align 4
//CHECK-NEXT:   store i256 %copy_val_20, i256* %copy_dst_20, align 4
//CHECK-NEXT:   %copy_src_21 = getelementptr i256, i256* %[[SRC_PTR]], i32 21
//CHECK-NEXT:   %copy_dst_21 = getelementptr i256, i256* %[[DST_PTR]], i32 21
//CHECK-NEXT:   %copy_val_21 = load i256, i256* %copy_src_21, align 4
//CHECK-NEXT:   store i256 %copy_val_21, i256* %copy_dst_21, align 4
//CHECK-NEXT:   %copy_src_22 = getelementptr i256, i256* %[[SRC_PTR]], i32 22
//CHECK-NEXT:   %copy_dst_22 = getelementptr i256, i256* %[[DST_PTR]], i32 22
//CHECK-NEXT:   %copy_val_22 = load i256, i256* %copy_src_22, align 4
//CHECK-NEXT:   store i256 %copy_val_22, i256* %copy_dst_22, align 4
//CHECK-NEXT:   %copy_src_23 = getelementptr i256, i256* %[[SRC_PTR]], i32 23
//CHECK-NEXT:   %copy_dst_23 = getelementptr i256, i256* %[[DST_PTR]], i32 23
//CHECK-NEXT:   %copy_val_23 = load i256, i256* %copy_src_23, align 4
//CHECK-NEXT:   store i256 %copy_val_23, i256* %copy_dst_23, align 4
//CHECK-NEXT:   %[[T03:[0-9a-zA-Z_.]+]] = bitcast [48 x i256]* %sum_0_arena to i256*
//CHECK-NEXT:   %[[SRC_PTR:[0-9a-zA-Z_.]+]] = call i256* @sum_0(i256* %[[T03]])
//CHECK-NEXT:   %[[DST_PTR:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 0
//CHECK-NEXT:   %copy_src_01 = getelementptr i256, i256* %[[SRC_PTR]], i32 0
//CHECK-NEXT:   %copy_dst_02 = getelementptr i256, i256* %[[DST_PTR]], i32 0
//CHECK-NEXT:   %copy_val_03 = load i256, i256* %copy_src_01, align 4
//CHECK-NEXT:   store i256 %copy_val_03, i256* %copy_dst_02, align 4
//CHECK-NEXT:   %copy_src_110 = getelementptr i256, i256* %[[SRC_PTR]], i32 1
//CHECK-NEXT:   %copy_dst_111 = getelementptr i256, i256* %[[DST_PTR]], i32 1
//CHECK-NEXT:   %copy_val_112 = load i256, i256* %copy_src_110, align 4
//CHECK-NEXT:   store i256 %copy_val_112, i256* %copy_dst_111, align 4
//CHECK-NEXT:   %copy_src_213 = getelementptr i256, i256* %[[SRC_PTR]], i32 2
//CHECK-NEXT:   %copy_dst_214 = getelementptr i256, i256* %[[DST_PTR]], i32 2
//CHECK-NEXT:   %copy_val_215 = load i256, i256* %copy_src_213, align 4
//CHECK-NEXT:   store i256 %copy_val_215, i256* %copy_dst_214, align 4
//CHECK-NEXT:   %copy_src_316 = getelementptr i256, i256* %[[SRC_PTR]], i32 3
//CHECK-NEXT:   %copy_dst_317 = getelementptr i256, i256* %[[DST_PTR]], i32 3
//CHECK-NEXT:   %copy_val_318 = load i256, i256* %copy_src_316, align 4
//CHECK-NEXT:   store i256 %copy_val_318, i256* %copy_dst_317, align 4
//CHECK-NEXT:   %copy_src_419 = getelementptr i256, i256* %[[SRC_PTR]], i32 4
//CHECK-NEXT:   %copy_dst_420 = getelementptr i256, i256* %[[DST_PTR]], i32 4
//CHECK-NEXT:   %copy_val_421 = load i256, i256* %copy_src_419, align 4
//CHECK-NEXT:   store i256 %copy_val_421, i256* %copy_dst_420, align 4
//CHECK-NEXT:   %copy_src_522 = getelementptr i256, i256* %[[SRC_PTR]], i32 5
//CHECK-NEXT:   %copy_dst_523 = getelementptr i256, i256* %[[DST_PTR]], i32 5
//CHECK-NEXT:   %copy_val_524 = load i256, i256* %copy_src_522, align 4
//CHECK-NEXT:   store i256 %copy_val_524, i256* %copy_dst_523, align 4
//CHECK-NEXT:   %copy_src_625 = getelementptr i256, i256* %[[SRC_PTR]], i32 6
//CHECK-NEXT:   %copy_dst_626 = getelementptr i256, i256* %[[DST_PTR]], i32 6
//CHECK-NEXT:   %copy_val_627 = load i256, i256* %copy_src_625, align 4
//CHECK-NEXT:   store i256 %copy_val_627, i256* %copy_dst_626, align 4
//CHECK-NEXT:   %copy_src_728 = getelementptr i256, i256* %[[SRC_PTR]], i32 7
//CHECK-NEXT:   %copy_dst_729 = getelementptr i256, i256* %[[DST_PTR]], i32 7
//CHECK-NEXT:   %copy_val_730 = load i256, i256* %copy_src_728, align 4
//CHECK-NEXT:   store i256 %copy_val_730, i256* %copy_dst_729, align 4
//CHECK-NEXT:   %copy_src_831 = getelementptr i256, i256* %[[SRC_PTR]], i32 8
//CHECK-NEXT:   %copy_dst_832 = getelementptr i256, i256* %[[DST_PTR]], i32 8
//CHECK-NEXT:   %copy_val_833 = load i256, i256* %copy_src_831, align 4
//CHECK-NEXT:   store i256 %copy_val_833, i256* %copy_dst_832, align 4
//CHECK-NEXT:   %copy_src_934 = getelementptr i256, i256* %[[SRC_PTR]], i32 9
//CHECK-NEXT:   %copy_dst_935 = getelementptr i256, i256* %[[DST_PTR]], i32 9
//CHECK-NEXT:   %copy_val_936 = load i256, i256* %copy_src_934, align 4
//CHECK-NEXT:   store i256 %copy_val_936, i256* %copy_dst_935, align 4
//CHECK-NEXT:   %copy_src_1037 = getelementptr i256, i256* %[[SRC_PTR]], i32 10
//CHECK-NEXT:   %copy_dst_1038 = getelementptr i256, i256* %[[DST_PTR]], i32 10
//CHECK-NEXT:   %copy_val_1039 = load i256, i256* %copy_src_1037, align 4
//CHECK-NEXT:   store i256 %copy_val_1039, i256* %copy_dst_1038, align 4
//CHECK-NEXT:   %copy_src_1140 = getelementptr i256, i256* %[[SRC_PTR]], i32 11
//CHECK-NEXT:   %copy_dst_1141 = getelementptr i256, i256* %[[DST_PTR]], i32 11
//CHECK-NEXT:   %copy_val_1142 = load i256, i256* %copy_src_1140, align 4
//CHECK-NEXT:   store i256 %copy_val_1142, i256* %copy_dst_1141, align 4
//CHECK-NEXT:   %copy_src_1243 = getelementptr i256, i256* %[[SRC_PTR]], i32 12
//CHECK-NEXT:   %copy_dst_1244 = getelementptr i256, i256* %[[DST_PTR]], i32 12
//CHECK-NEXT:   %copy_val_1245 = load i256, i256* %copy_src_1243, align 4
//CHECK-NEXT:   store i256 %copy_val_1245, i256* %copy_dst_1244, align 4
//CHECK-NEXT:   %copy_src_1346 = getelementptr i256, i256* %[[SRC_PTR]], i32 13
//CHECK-NEXT:   %copy_dst_1347 = getelementptr i256, i256* %[[DST_PTR]], i32 13
//CHECK-NEXT:   %copy_val_1348 = load i256, i256* %copy_src_1346, align 4
//CHECK-NEXT:   store i256 %copy_val_1348, i256* %copy_dst_1347, align 4
//CHECK-NEXT:   %copy_src_1449 = getelementptr i256, i256* %[[SRC_PTR]], i32 14
//CHECK-NEXT:   %copy_dst_1450 = getelementptr i256, i256* %[[DST_PTR]], i32 14
//CHECK-NEXT:   %copy_val_1451 = load i256, i256* %copy_src_1449, align 4
//CHECK-NEXT:   store i256 %copy_val_1451, i256* %copy_dst_1450, align 4
//CHECK-NEXT:   %copy_src_1552 = getelementptr i256, i256* %[[SRC_PTR]], i32 15
//CHECK-NEXT:   %copy_dst_1553 = getelementptr i256, i256* %[[DST_PTR]], i32 15
//CHECK-NEXT:   %copy_val_1554 = load i256, i256* %copy_src_1552, align 4
//CHECK-NEXT:   store i256 %copy_val_1554, i256* %copy_dst_1553, align 4
//CHECK-NEXT:   %copy_src_1655 = getelementptr i256, i256* %[[SRC_PTR]], i32 16
//CHECK-NEXT:   %copy_dst_1656 = getelementptr i256, i256* %[[DST_PTR]], i32 16
//CHECK-NEXT:   %copy_val_1657 = load i256, i256* %copy_src_1655, align 4
//CHECK-NEXT:   store i256 %copy_val_1657, i256* %copy_dst_1656, align 4
//CHECK-NEXT:   %copy_src_1758 = getelementptr i256, i256* %[[SRC_PTR]], i32 17
//CHECK-NEXT:   %copy_dst_1759 = getelementptr i256, i256* %[[DST_PTR]], i32 17
//CHECK-NEXT:   %copy_val_1760 = load i256, i256* %copy_src_1758, align 4
//CHECK-NEXT:   store i256 %copy_val_1760, i256* %copy_dst_1759, align 4
//CHECK-NEXT:   %copy_src_1861 = getelementptr i256, i256* %[[SRC_PTR]], i32 18
//CHECK-NEXT:   %copy_dst_1862 = getelementptr i256, i256* %[[DST_PTR]], i32 18
//CHECK-NEXT:   %copy_val_1863 = load i256, i256* %copy_src_1861, align 4
//CHECK-NEXT:   store i256 %copy_val_1863, i256* %copy_dst_1862, align 4
//CHECK-NEXT:   %copy_src_1964 = getelementptr i256, i256* %[[SRC_PTR]], i32 19
//CHECK-NEXT:   %copy_dst_1965 = getelementptr i256, i256* %[[DST_PTR]], i32 19
//CHECK-NEXT:   %copy_val_1966 = load i256, i256* %copy_src_1964, align 4
//CHECK-NEXT:   store i256 %copy_val_1966, i256* %copy_dst_1965, align 4
//CHECK-NEXT:   %copy_src_2067 = getelementptr i256, i256* %[[SRC_PTR]], i32 20
//CHECK-NEXT:   %copy_dst_2068 = getelementptr i256, i256* %[[DST_PTR]], i32 20
//CHECK-NEXT:   %copy_val_2069 = load i256, i256* %copy_src_2067, align 4
//CHECK-NEXT:   store i256 %copy_val_2069, i256* %copy_dst_2068, align 4
//CHECK-NEXT:   %copy_src_2170 = getelementptr i256, i256* %[[SRC_PTR]], i32 21
//CHECK-NEXT:   %copy_dst_2171 = getelementptr i256, i256* %[[DST_PTR]], i32 21
//CHECK-NEXT:   %copy_val_2172 = load i256, i256* %copy_src_2170, align 4
//CHECK-NEXT:   store i256 %copy_val_2172, i256* %copy_dst_2171, align 4
//CHECK-NEXT:   %copy_src_2273 = getelementptr i256, i256* %[[SRC_PTR]], i32 22
//CHECK-NEXT:   %copy_dst_2274 = getelementptr i256, i256* %[[DST_PTR]], i32 22
//CHECK-NEXT:   %copy_val_2275 = load i256, i256* %copy_src_2273, align 4
//CHECK-NEXT:   store i256 %copy_val_2275, i256* %copy_dst_2274, align 4
//CHECK-NEXT:   %copy_src_2376 = getelementptr i256, i256* %[[SRC_PTR]], i32 23
//CHECK-NEXT:   %copy_dst_2377 = getelementptr i256, i256* %[[DST_PTR]], i32 23
//CHECK-NEXT:   %copy_val_2378 = load i256, i256* %copy_src_2376, align 4
//CHECK-NEXT:   store i256 %copy_val_2378, i256* %copy_dst_2377, align 4
//CHECK-NEXT:   br label %prologue
