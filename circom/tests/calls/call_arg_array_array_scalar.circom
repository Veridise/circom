pragma circom 2.1.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

function sum(a, b, c) {
    return a[0][0][0] + a[1][0][0] + a[2][0][0] + a[3][0][0] + b[0][0] + b[1][2] + c;
}

template CallArgTest() {
    signal input x[4][2][3];
    signal input y[2][3];
    signal input z;
    signal output q;

    q <-- sum(x, y, z);
}

component main = CallArgTest();

//CHECK-LABEL: define{{.*}} i256 @sum_0(i256* %0){{.*}} {
//CHECK-NEXT: sum_0:
//CHECK-NEXT:   br label %return1
//CHECK-EMPTY:
//CHECK-NEXT: return1:
//CHECK-NEXT:   %1 = getelementptr i256, i256* %0, i32 0
//CHECK-NEXT:   %2 = load i256, i256* %1, align 4
//CHECK-NEXT:   %3 = getelementptr i256, i256* %0, i32 6
//CHECK-NEXT:   %4 = load i256, i256* %3, align 4
//CHECK-NEXT:   %call.fr_add = call i256 @fr_add(i256 %2, i256 %4)
//CHECK-NEXT:   %5 = getelementptr i256, i256* %0, i32 12
//CHECK-NEXT:   %6 = load i256, i256* %5, align 4
//CHECK-NEXT:   %call.fr_add1 = call i256 @fr_add(i256 %call.fr_add, i256 %6)
//CHECK-NEXT:   %7 = getelementptr i256, i256* %0, i32 18
//CHECK-NEXT:   %8 = load i256, i256* %7, align 4
//CHECK-NEXT:   %call.fr_add2 = call i256 @fr_add(i256 %call.fr_add1, i256 %8)
//CHECK-NEXT:   %9 = getelementptr i256, i256* %0, i32 24
//CHECK-NEXT:   %10 = load i256, i256* %9, align 4
//CHECK-NEXT:   %call.fr_add3 = call i256 @fr_add(i256 %call.fr_add2, i256 %10)
//CHECK-NEXT:   %11 = getelementptr i256, i256* %0, i32 29
//CHECK-NEXT:   %12 = load i256, i256* %11, align 4
//CHECK-NEXT:   %call.fr_add4 = call i256 @fr_add(i256 %call.fr_add3, i256 %12)
//CHECK-NEXT:   %13 = getelementptr i256, i256* %0, i32 30
//CHECK-NEXT:   %14 = load i256, i256* %13, align 4
//CHECK-NEXT:   %call.fr_add5 = call i256 @fr_add(i256 %call.fr_add4, i256 %14)
//CHECK-NEXT:   ret i256 %call.fr_add5
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @CallArgTest_0_run([0 x i256]* %0){{.*}} {
//CHECK-NEXT: prelude:
//CHECK-NEXT:   %lvars = alloca [0 x i256], align 8
//CHECK-NEXT:   %subcmps = alloca [0 x { [0 x i256]*, i32 }], align 8
//CHECK-NEXT:   br label %call1
//CHECK-EMPTY:
//CHECK-NEXT: call1:
//CHECK-NEXT:   %sum_0_arena = alloca [31 x i256], align 8
//CHECK-NEXT:   %1 = getelementptr [31 x i256], [31 x i256]* %sum_0_arena, i32 0, i32 0
//CHECK-NEXT:   %2 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 1
//CHECK-NEXT:   %copy_src_0 = getelementptr i256, i256* %2, i32 0
//CHECK-NEXT:   %copy_dst_0 = getelementptr i256, i256* %1, i32 0
//CHECK-NEXT:   %copy_val_0 = load i256, i256* %copy_src_0, align 4
//CHECK-NEXT:   store i256 %copy_val_0, i256* %copy_dst_0, align 4
//CHECK-NEXT:   %copy_src_1 = getelementptr i256, i256* %2, i32 1
//CHECK-NEXT:   %copy_dst_1 = getelementptr i256, i256* %1, i32 1
//CHECK-NEXT:   %copy_val_1 = load i256, i256* %copy_src_1, align 4
//CHECK-NEXT:   store i256 %copy_val_1, i256* %copy_dst_1, align 4
//CHECK-NEXT:   %copy_src_2 = getelementptr i256, i256* %2, i32 2
//CHECK-NEXT:   %copy_dst_2 = getelementptr i256, i256* %1, i32 2
//CHECK-NEXT:   %copy_val_2 = load i256, i256* %copy_src_2, align 4
//CHECK-NEXT:   store i256 %copy_val_2, i256* %copy_dst_2, align 4
//CHECK-NEXT:   %copy_src_3 = getelementptr i256, i256* %2, i32 3
//CHECK-NEXT:   %copy_dst_3 = getelementptr i256, i256* %1, i32 3
//CHECK-NEXT:   %copy_val_3 = load i256, i256* %copy_src_3, align 4
//CHECK-NEXT:   store i256 %copy_val_3, i256* %copy_dst_3, align 4
//CHECK-NEXT:   %copy_src_4 = getelementptr i256, i256* %2, i32 4
//CHECK-NEXT:   %copy_dst_4 = getelementptr i256, i256* %1, i32 4
//CHECK-NEXT:   %copy_val_4 = load i256, i256* %copy_src_4, align 4
//CHECK-NEXT:   store i256 %copy_val_4, i256* %copy_dst_4, align 4
//CHECK-NEXT:   %copy_src_5 = getelementptr i256, i256* %2, i32 5
//CHECK-NEXT:   %copy_dst_5 = getelementptr i256, i256* %1, i32 5
//CHECK-NEXT:   %copy_val_5 = load i256, i256* %copy_src_5, align 4
//CHECK-NEXT:   store i256 %copy_val_5, i256* %copy_dst_5, align 4
//CHECK-NEXT:   %copy_src_6 = getelementptr i256, i256* %2, i32 6
//CHECK-NEXT:   %copy_dst_6 = getelementptr i256, i256* %1, i32 6
//CHECK-NEXT:   %copy_val_6 = load i256, i256* %copy_src_6, align 4
//CHECK-NEXT:   store i256 %copy_val_6, i256* %copy_dst_6, align 4
//CHECK-NEXT:   %copy_src_7 = getelementptr i256, i256* %2, i32 7
//CHECK-NEXT:   %copy_dst_7 = getelementptr i256, i256* %1, i32 7
//CHECK-NEXT:   %copy_val_7 = load i256, i256* %copy_src_7, align 4
//CHECK-NEXT:   store i256 %copy_val_7, i256* %copy_dst_7, align 4
//CHECK-NEXT:   %copy_src_8 = getelementptr i256, i256* %2, i32 8
//CHECK-NEXT:   %copy_dst_8 = getelementptr i256, i256* %1, i32 8
//CHECK-NEXT:   %copy_val_8 = load i256, i256* %copy_src_8, align 4
//CHECK-NEXT:   store i256 %copy_val_8, i256* %copy_dst_8, align 4
//CHECK-NEXT:   %copy_src_9 = getelementptr i256, i256* %2, i32 9
//CHECK-NEXT:   %copy_dst_9 = getelementptr i256, i256* %1, i32 9
//CHECK-NEXT:   %copy_val_9 = load i256, i256* %copy_src_9, align 4
//CHECK-NEXT:   store i256 %copy_val_9, i256* %copy_dst_9, align 4
//CHECK-NEXT:   %copy_src_10 = getelementptr i256, i256* %2, i32 10
//CHECK-NEXT:   %copy_dst_10 = getelementptr i256, i256* %1, i32 10
//CHECK-NEXT:   %copy_val_10 = load i256, i256* %copy_src_10, align 4
//CHECK-NEXT:   store i256 %copy_val_10, i256* %copy_dst_10, align 4
//CHECK-NEXT:   %copy_src_11 = getelementptr i256, i256* %2, i32 11
//CHECK-NEXT:   %copy_dst_11 = getelementptr i256, i256* %1, i32 11
//CHECK-NEXT:   %copy_val_11 = load i256, i256* %copy_src_11, align 4
//CHECK-NEXT:   store i256 %copy_val_11, i256* %copy_dst_11, align 4
//CHECK-NEXT:   %copy_src_12 = getelementptr i256, i256* %2, i32 12
//CHECK-NEXT:   %copy_dst_12 = getelementptr i256, i256* %1, i32 12
//CHECK-NEXT:   %copy_val_12 = load i256, i256* %copy_src_12, align 4
//CHECK-NEXT:   store i256 %copy_val_12, i256* %copy_dst_12, align 4
//CHECK-NEXT:   %copy_src_13 = getelementptr i256, i256* %2, i32 13
//CHECK-NEXT:   %copy_dst_13 = getelementptr i256, i256* %1, i32 13
//CHECK-NEXT:   %copy_val_13 = load i256, i256* %copy_src_13, align 4
//CHECK-NEXT:   store i256 %copy_val_13, i256* %copy_dst_13, align 4
//CHECK-NEXT:   %copy_src_14 = getelementptr i256, i256* %2, i32 14
//CHECK-NEXT:   %copy_dst_14 = getelementptr i256, i256* %1, i32 14
//CHECK-NEXT:   %copy_val_14 = load i256, i256* %copy_src_14, align 4
//CHECK-NEXT:   store i256 %copy_val_14, i256* %copy_dst_14, align 4
//CHECK-NEXT:   %copy_src_15 = getelementptr i256, i256* %2, i32 15
//CHECK-NEXT:   %copy_dst_15 = getelementptr i256, i256* %1, i32 15
//CHECK-NEXT:   %copy_val_15 = load i256, i256* %copy_src_15, align 4
//CHECK-NEXT:   store i256 %copy_val_15, i256* %copy_dst_15, align 4
//CHECK-NEXT:   %copy_src_16 = getelementptr i256, i256* %2, i32 16
//CHECK-NEXT:   %copy_dst_16 = getelementptr i256, i256* %1, i32 16
//CHECK-NEXT:   %copy_val_16 = load i256, i256* %copy_src_16, align 4
//CHECK-NEXT:   store i256 %copy_val_16, i256* %copy_dst_16, align 4
//CHECK-NEXT:   %copy_src_17 = getelementptr i256, i256* %2, i32 17
//CHECK-NEXT:   %copy_dst_17 = getelementptr i256, i256* %1, i32 17
//CHECK-NEXT:   %copy_val_17 = load i256, i256* %copy_src_17, align 4
//CHECK-NEXT:   store i256 %copy_val_17, i256* %copy_dst_17, align 4
//CHECK-NEXT:   %copy_src_18 = getelementptr i256, i256* %2, i32 18
//CHECK-NEXT:   %copy_dst_18 = getelementptr i256, i256* %1, i32 18
//CHECK-NEXT:   %copy_val_18 = load i256, i256* %copy_src_18, align 4
//CHECK-NEXT:   store i256 %copy_val_18, i256* %copy_dst_18, align 4
//CHECK-NEXT:   %copy_src_19 = getelementptr i256, i256* %2, i32 19
//CHECK-NEXT:   %copy_dst_19 = getelementptr i256, i256* %1, i32 19
//CHECK-NEXT:   %copy_val_19 = load i256, i256* %copy_src_19, align 4
//CHECK-NEXT:   store i256 %copy_val_19, i256* %copy_dst_19, align 4
//CHECK-NEXT:   %copy_src_20 = getelementptr i256, i256* %2, i32 20
//CHECK-NEXT:   %copy_dst_20 = getelementptr i256, i256* %1, i32 20
//CHECK-NEXT:   %copy_val_20 = load i256, i256* %copy_src_20, align 4
//CHECK-NEXT:   store i256 %copy_val_20, i256* %copy_dst_20, align 4
//CHECK-NEXT:   %copy_src_21 = getelementptr i256, i256* %2, i32 21
//CHECK-NEXT:   %copy_dst_21 = getelementptr i256, i256* %1, i32 21
//CHECK-NEXT:   %copy_val_21 = load i256, i256* %copy_src_21, align 4
//CHECK-NEXT:   store i256 %copy_val_21, i256* %copy_dst_21, align 4
//CHECK-NEXT:   %copy_src_22 = getelementptr i256, i256* %2, i32 22
//CHECK-NEXT:   %copy_dst_22 = getelementptr i256, i256* %1, i32 22
//CHECK-NEXT:   %copy_val_22 = load i256, i256* %copy_src_22, align 4
//CHECK-NEXT:   store i256 %copy_val_22, i256* %copy_dst_22, align 4
//CHECK-NEXT:   %copy_src_23 = getelementptr i256, i256* %2, i32 23
//CHECK-NEXT:   %copy_dst_23 = getelementptr i256, i256* %1, i32 23
//CHECK-NEXT:   %copy_val_23 = load i256, i256* %copy_src_23, align 4
//CHECK-NEXT:   store i256 %copy_val_23, i256* %copy_dst_23, align 4
//CHECK-NEXT:   %3 = getelementptr [31 x i256], [31 x i256]* %sum_0_arena, i32 0, i32 24
//CHECK-NEXT:   %4 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 25
//CHECK-NEXT:   %copy_src_01 = getelementptr i256, i256* %4, i32 0
//CHECK-NEXT:   %copy_dst_02 = getelementptr i256, i256* %3, i32 0
//CHECK-NEXT:   %copy_val_03 = load i256, i256* %copy_src_01, align 4
//CHECK-NEXT:   store i256 %copy_val_03, i256* %copy_dst_02, align 4
//CHECK-NEXT:   %copy_src_110 = getelementptr i256, i256* %4, i32 1
//CHECK-NEXT:   %copy_dst_111 = getelementptr i256, i256* %3, i32 1
//CHECK-NEXT:   %copy_val_112 = load i256, i256* %copy_src_110, align 4
//CHECK-NEXT:   store i256 %copy_val_112, i256* %copy_dst_111, align 4
//CHECK-NEXT:   %copy_src_213 = getelementptr i256, i256* %4, i32 2
//CHECK-NEXT:   %copy_dst_214 = getelementptr i256, i256* %3, i32 2
//CHECK-NEXT:   %copy_val_215 = load i256, i256* %copy_src_213, align 4
//CHECK-NEXT:   store i256 %copy_val_215, i256* %copy_dst_214, align 4
//CHECK-NEXT:   %copy_src_316 = getelementptr i256, i256* %4, i32 3
//CHECK-NEXT:   %copy_dst_317 = getelementptr i256, i256* %3, i32 3
//CHECK-NEXT:   %copy_val_318 = load i256, i256* %copy_src_316, align 4
//CHECK-NEXT:   store i256 %copy_val_318, i256* %copy_dst_317, align 4
//CHECK-NEXT:   %copy_src_419 = getelementptr i256, i256* %4, i32 4
//CHECK-NEXT:   %copy_dst_420 = getelementptr i256, i256* %3, i32 4
//CHECK-NEXT:   %copy_val_421 = load i256, i256* %copy_src_419, align 4
//CHECK-NEXT:   store i256 %copy_val_421, i256* %copy_dst_420, align 4
//CHECK-NEXT:   %copy_src_522 = getelementptr i256, i256* %4, i32 5
//CHECK-NEXT:   %copy_dst_523 = getelementptr i256, i256* %3, i32 5
//CHECK-NEXT:   %copy_val_524 = load i256, i256* %copy_src_522, align 4
//CHECK-NEXT:   store i256 %copy_val_524, i256* %copy_dst_523, align 4
//CHECK-NEXT:   %5 = getelementptr [31 x i256], [31 x i256]* %sum_0_arena, i32 0, i32 30
//CHECK-NEXT:   %6 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 31
//CHECK-NEXT:   %7 = load i256, i256* %6, align 4
//CHECK-NEXT:   store i256 %7, i256* %5, align 4
//CHECK-NEXT:   %8 = bitcast [31 x i256]* %sum_0_arena to i256*
//CHECK-NEXT:   %call.sum_0 = call i256 @sum_0(i256* %8)
//CHECK-NEXT:   %9 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 0
//CHECK-NEXT:   store i256 %call.sum_0, i256* %9, align 4
//CHECK-NEXT:   br label %prologue
