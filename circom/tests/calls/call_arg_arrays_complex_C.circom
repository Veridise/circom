pragma circom 2.1.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

function sum(a, b) {
    b[0] = a[1];
    b[1] = a[0];
    return a[0][0];
}

template CallArgTest() {
    signal input x[2][3];
    signal input y[2][3];
    signal output z[2][3];
    signal output q;

    q <-- sum(x, y);
}

component main = CallArgTest();


//CHECK-LABEL: define{{.*}} i256 @sum_0(i256* %0){{.*}} {
//CHECK:      store1:
//CHECK-NEXT:   %[[DST_PTR:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %0, i32 6
//CHECK-NEXT:   %[[SRC_PTR:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %0, i32 3
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
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY:
//CHECK-NEXT: store2:
//CHECK-NEXT:   %[[DST_PTR:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %0, i32 9
//CHECK-NEXT:   %[[SRC_PTR:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %0, i32 0
//CHECK-NEXT:   %copy_src_01 = getelementptr i256, i256* %[[SRC_PTR]], i32 0
//CHECK-NEXT:   %copy_dst_02 = getelementptr i256, i256* %[[DST_PTR]], i32 0
//CHECK-NEXT:   %copy_val_03 = load i256, i256* %copy_src_01, align 4
//CHECK-NEXT:   store i256 %copy_val_03, i256* %copy_dst_02, align 4
//CHECK-NEXT:   %copy_src_14 = getelementptr i256, i256* %[[SRC_PTR]], i32 1
//CHECK-NEXT:   %copy_dst_15 = getelementptr i256, i256* %[[DST_PTR]], i32 1
//CHECK-NEXT:   %copy_val_16 = load i256, i256* %copy_src_14, align 4
//CHECK-NEXT:   store i256 %copy_val_16, i256* %copy_dst_15, align 4
//CHECK-NEXT:   %copy_src_27 = getelementptr i256, i256* %[[SRC_PTR]], i32 2
//CHECK-NEXT:   %copy_dst_28 = getelementptr i256, i256* %[[DST_PTR]], i32 2
//CHECK-NEXT:   %copy_val_29 = load i256, i256* %copy_src_27, align 4
//CHECK-NEXT:   store i256 %copy_val_29, i256* %copy_dst_28, align 4
//CHECK-NEXT:   br label %return3
//CHECK-EMPTY:
//CHECK-NEXT: return3:
//CHECK-NEXT:   %[[T09:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %0, i32 0
//CHECK-NEXT:   %[[T10:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T09]], align 4
//CHECK-NEXT:   ret i256 %[[T10]]
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @CallArgTest_0_run([0 x i256]* %0){{.*}} {
//CHECK-NEXT: prelude:
//CHECK-NEXT:   %lvars = alloca [0 x i256], align 8
//CHECK-NEXT:   %subcmps = alloca [0 x { [0 x i256]*, i32 }], align 8
//CHECK-NEXT:   br label %call1
//CHECK-EMPTY:
//CHECK-NEXT: call1:
//CHECK-NEXT:   %sum_0_arena = alloca [12 x i256], align 8
//CHECK-NEXT:   %[[DST_PTR:[0-9a-zA-Z_\.]+]] = getelementptr [12 x i256], [12 x i256]* %sum_0_arena, i32 0, i32 0
//CHECK-NEXT:   %[[SRC_PTR:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 7
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
//CHECK-NEXT:   %[[DST_PTR:[0-9a-zA-Z_\.]+]] = getelementptr [12 x i256], [12 x i256]* %sum_0_arena, i32 0, i32 6
//CHECK-NEXT:   %[[SRC_PTR:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 13
//CHECK-NEXT:   %copy_src_01 = getelementptr i256, i256* %[[SRC_PTR]], i32 0
//CHECK-NEXT:   %copy_dst_02 = getelementptr i256, i256* %[[DST_PTR]], i32 0
//CHECK-NEXT:   %copy_val_03 = load i256, i256* %copy_src_01, align 4
//CHECK-NEXT:   store i256 %copy_val_03, i256* %copy_dst_02, align 4
//CHECK-NEXT:   %copy_src_14 = getelementptr i256, i256* %[[SRC_PTR]], i32 1
//CHECK-NEXT:   %copy_dst_15 = getelementptr i256, i256* %[[DST_PTR]], i32 1
//CHECK-NEXT:   %copy_val_16 = load i256, i256* %copy_src_14, align 4
//CHECK-NEXT:   store i256 %copy_val_16, i256* %copy_dst_15, align 4
//CHECK-NEXT:   %copy_src_27 = getelementptr i256, i256* %[[SRC_PTR]], i32 2
//CHECK-NEXT:   %copy_dst_28 = getelementptr i256, i256* %[[DST_PTR]], i32 2
//CHECK-NEXT:   %copy_val_29 = load i256, i256* %copy_src_27, align 4
//CHECK-NEXT:   store i256 %copy_val_29, i256* %copy_dst_28, align 4
//CHECK-NEXT:   %copy_src_310 = getelementptr i256, i256* %[[SRC_PTR]], i32 3
//CHECK-NEXT:   %copy_dst_311 = getelementptr i256, i256* %[[DST_PTR]], i32 3
//CHECK-NEXT:   %copy_val_312 = load i256, i256* %copy_src_310, align 4
//CHECK-NEXT:   store i256 %copy_val_312, i256* %copy_dst_311, align 4
//CHECK-NEXT:   %copy_src_413 = getelementptr i256, i256* %[[SRC_PTR]], i32 4
//CHECK-NEXT:   %copy_dst_414 = getelementptr i256, i256* %[[DST_PTR]], i32 4
//CHECK-NEXT:   %copy_val_415 = load i256, i256* %copy_src_413, align 4
//CHECK-NEXT:   store i256 %copy_val_415, i256* %copy_dst_414, align 4
//CHECK-NEXT:   %copy_src_516 = getelementptr i256, i256* %[[SRC_PTR]], i32 5
//CHECK-NEXT:   %copy_dst_517 = getelementptr i256, i256* %[[DST_PTR]], i32 5
//CHECK-NEXT:   %copy_val_518 = load i256, i256* %copy_src_516, align 4
//CHECK-NEXT:   store i256 %copy_val_518, i256* %copy_dst_517, align 4
//CHECK-NEXT:   %[[T05:[0-9a-zA-Z_\.]+]] = bitcast [12 x i256]* %sum_0_arena to i256*
//CHECK-NEXT:   %call.sum_0 = call i256 @sum_0(i256* %[[T05]])
//CHECK-NEXT:   %[[T06:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 6
//CHECK-NEXT:   store i256 %call.sum_0, i256* %[[T06]], align 4
//CHECK-NEXT:   br label %prologue
