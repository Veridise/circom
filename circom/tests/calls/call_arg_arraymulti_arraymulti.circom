pragma circom 2.1.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

function sum(a, b) {
    var agg = 0;
    for (var i = 0; i < 3; i++) {
        for (var j = 0; j < 2; j++) {
            agg += a[i][j] - b[i][j];
        }
    }
    return agg;
}

template CallArgTest() {
    signal input x[3][2];
    signal input y[3][2];
    signal output a;

    a <-- sum(x, y);
}

component main = CallArgTest();

//CHECK-LABEL: define{{.*}} void @..generated..loop.body.{{[0-9]+}}([0 x i256]* %lvars, [0 x i256]* %signals, i256* %var_0, i256* %var_1){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_1:[0-9]+]]:
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %0 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 12
//CHECK-NEXT:   %1 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 12
//CHECK-NEXT:   %2 = load i256, i256* %1, align 4
//CHECK-NEXT:   %3 = getelementptr i256, i256* %var_0, i32 0
//CHECK-NEXT:   %4 = load i256, i256* %3, align 4
//CHECK-NEXT:   %5 = getelementptr i256, i256* %var_1, i32 0
//CHECK-NEXT:   %6 = load i256, i256* %5, align 4
//CHECK-NEXT:   %call.fr_sub = call i256 @fr_sub(i256 %4, i256 %6)
//CHECK-NEXT:   %call.fr_add = call i256 @fr_add(i256 %2, i256 %call.fr_sub)
//CHECK-NEXT:   store i256 %call.fr_add, i256* %0, align 4
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %7 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 14
//CHECK-NEXT:   %8 = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 14
//CHECK-NEXT:   %9 = load i256, i256* %8, align 4
//CHECK-NEXT:   %call.fr_add1 = call i256 @fr_add(i256 %9, i256 1)
//CHECK-NEXT:   store i256 %call.fr_add1, i256* %7, align 4
//CHECK-NEXT:   br label %return3
//CHECK-EMPTY: 
//CHECK-NEXT: return3:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} i256 @sum_0(i256* %0){{.*}} {
//CHECK-NEXT: sum_0:
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY:
//CHECK-NEXT: store1:
//CHECK-NEXT:   %[[T01:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %0, i32 12
//CHECK-NEXT:   store i256 0, i256* %[[T01]], align 4
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY:
//CHECK-NEXT: store2:
//CHECK-NEXT:   %[[T02:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %0, i32 13
//CHECK-NEXT:   store i256 0, i256* %[[T02]], align 4
//CHECK-NEXT:   br label %unrolled_loop3
//CHECK-EMPTY:
//CHECK-NEXT: unrolled_loop3:
//CHECK-NEXT:   %3 = getelementptr i256, i256* %0, i32 14
//CHECK-NEXT:   store i256 0, i256* %3, align 4
//CHECK-NEXT:   %4 = bitcast i256* %0 to [0 x i256]*
//CHECK-NEXT:   %5 = bitcast i256* %0 to [0 x i256]*
//CHECK-NEXT:   %6 = getelementptr [0 x i256], [0 x i256]* %5, i32 0, i256 0
//CHECK-NEXT:   %7 = bitcast i256* %0 to [0 x i256]*
//CHECK-NEXT:   %8 = getelementptr [0 x i256], [0 x i256]* %7, i32 0, i256 6
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %4, [0 x i256]* null, i256* %6, i256* %8)
//CHECK-NEXT:   %9 = bitcast i256* %0 to [0 x i256]*
//CHECK-NEXT:   %10 = bitcast i256* %0 to [0 x i256]*
//CHECK-NEXT:   %11 = getelementptr [0 x i256], [0 x i256]* %10, i32 0, i256 1
//CHECK-NEXT:   %12 = bitcast i256* %0 to [0 x i256]*
//CHECK-NEXT:   %13 = getelementptr [0 x i256], [0 x i256]* %12, i32 0, i256 7
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %9, [0 x i256]* null, i256* %11, i256* %13)
//CHECK-NEXT:   %14 = getelementptr i256, i256* %0, i32 13
//CHECK-NEXT:   %15 = getelementptr i256, i256* %0, i32 13
//CHECK-NEXT:   %16 = load i256, i256* %15, align 4
//CHECK-NEXT:   %call.fr_add = call i256 @fr_add(i256 %16, i256 1)
//CHECK-NEXT:   store i256 %call.fr_add, i256* %14, align 4
//CHECK-NEXT:   %17 = getelementptr i256, i256* %0, i32 14
//CHECK-NEXT:   store i256 0, i256* %17, align 4
//CHECK-NEXT:   %18 = bitcast i256* %0 to [0 x i256]*
//CHECK-NEXT:   %19 = bitcast i256* %0 to [0 x i256]*
//CHECK-NEXT:   %20 = getelementptr [0 x i256], [0 x i256]* %19, i32 0, i256 2
//CHECK-NEXT:   %21 = bitcast i256* %0 to [0 x i256]*
//CHECK-NEXT:   %22 = getelementptr [0 x i256], [0 x i256]* %21, i32 0, i256 8
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %18, [0 x i256]* null, i256* %20, i256* %22)
//CHECK-NEXT:   %23 = bitcast i256* %0 to [0 x i256]*
//CHECK-NEXT:   %24 = bitcast i256* %0 to [0 x i256]*
//CHECK-NEXT:   %25 = getelementptr [0 x i256], [0 x i256]* %24, i32 0, i256 3
//CHECK-NEXT:   %26 = bitcast i256* %0 to [0 x i256]*
//CHECK-NEXT:   %27 = getelementptr [0 x i256], [0 x i256]* %26, i32 0, i256 9
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %23, [0 x i256]* null, i256* %25, i256* %27)
//CHECK-NEXT:   %28 = getelementptr i256, i256* %0, i32 13
//CHECK-NEXT:   %29 = getelementptr i256, i256* %0, i32 13
//CHECK-NEXT:   %30 = load i256, i256* %29, align 4
//CHECK-NEXT:   %call.fr_add14 = call i256 @fr_add(i256 %30, i256 1)
//CHECK-NEXT:   store i256 %call.fr_add14, i256* %28, align 4
//CHECK-NEXT:   %31 = getelementptr i256, i256* %0, i32 14
//CHECK-NEXT:   store i256 0, i256* %31, align 4
//CHECK-NEXT:   %32 = bitcast i256* %0 to [0 x i256]*
//CHECK-NEXT:   %33 = bitcast i256* %0 to [0 x i256]*
//CHECK-NEXT:   %34 = getelementptr [0 x i256], [0 x i256]* %33, i32 0, i256 4
//CHECK-NEXT:   %35 = bitcast i256* %0 to [0 x i256]*
//CHECK-NEXT:   %36 = getelementptr [0 x i256], [0 x i256]* %35, i32 0, i256 10
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %32, [0 x i256]* null, i256* %34, i256* %36)
//CHECK-NEXT:   %37 = bitcast i256* %0 to [0 x i256]*
//CHECK-NEXT:   %38 = bitcast i256* %0 to [0 x i256]*
//CHECK-NEXT:   %39 = getelementptr [0 x i256], [0 x i256]* %38, i32 0, i256 5
//CHECK-NEXT:   %40 = bitcast i256* %0 to [0 x i256]*
//CHECK-NEXT:   %41 = getelementptr [0 x i256], [0 x i256]* %40, i32 0, i256 11
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %37, [0 x i256]* null, i256* %39, i256* %41)
//CHECK-NEXT:   %42 = getelementptr i256, i256* %0, i32 13
//CHECK-NEXT:   %43 = getelementptr i256, i256* %0, i32 13
//CHECK-NEXT:   %44 = load i256, i256* %43, align 4
//CHECK-NEXT:   %call.fr_add23 = call i256 @fr_add(i256 %44, i256 1)
//CHECK-NEXT:   store i256 %call.fr_add23, i256* %42, align 4
//CHECK-NEXT:   br label %return4
//CHECK-EMPTY:
//CHECK-NEXT: return4:
//CHECK-NEXT:   %[[T29:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %0, i32 12
//CHECK-NEXT:   %[[T30:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T29]], align 4
//CHECK-NEXT:   ret i256 %[[T30]]
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @CallArgTest_0_run([0 x i256]* %0){{.*}} {
//CHECK-NEXT: prelude:
//CHECK-NEXT:   %lvars = alloca [0 x i256], align 8
//CHECK-NEXT:   %subcmps = alloca [0 x { [0 x i256]*, i32 }], align 8
//CHECK-NEXT:   br label %call1
//CHECK-EMPTY:
//CHECK-NEXT: call1:
//CHECK-NEXT:   %sum_0_arena = alloca [15 x i256], align 8
//CHECK-NEXT:   %[[DST_PTR:[0-9a-zA-Z_.]+]] = getelementptr [15 x i256], [15 x i256]* %sum_0_arena, i32 0, i32 0
//CHECK-NEXT:   %[[SRC_PTR:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 1
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
//CHECK-NEXT:   %3 = getelementptr [15 x i256], [15 x i256]* %sum_0_arena, i32 0, i32 6
//CHECK-NEXT:   %4 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 7
//CHECK-NEXT:   %copy_src_01 = getelementptr i256, i256* %4, i32 0
//CHECK-NEXT:   %copy_dst_02 = getelementptr i256, i256* %3, i32 0
//CHECK-NEXT:   %copy_val_03 = load i256, i256* %copy_src_01, align 4
//CHECK-NEXT:   store i256 %copy_val_03, i256* %copy_dst_02, align 4
//CHECK-NEXT:   %copy_src_14 = getelementptr i256, i256* %4, i32 1
//CHECK-NEXT:   %copy_dst_15 = getelementptr i256, i256* %3, i32 1
//CHECK-NEXT:   %copy_val_16 = load i256, i256* %copy_src_14, align 4
//CHECK-NEXT:   store i256 %copy_val_16, i256* %copy_dst_15, align 4
//CHECK-NEXT:   %copy_src_27 = getelementptr i256, i256* %4, i32 2
//CHECK-NEXT:   %copy_dst_28 = getelementptr i256, i256* %3, i32 2
//CHECK-NEXT:   %copy_val_29 = load i256, i256* %copy_src_27, align 4
//CHECK-NEXT:   store i256 %copy_val_29, i256* %copy_dst_28, align 4
//CHECK-NEXT:   %copy_src_310 = getelementptr i256, i256* %4, i32 3
//CHECK-NEXT:   %copy_dst_311 = getelementptr i256, i256* %3, i32 3
//CHECK-NEXT:   %copy_val_312 = load i256, i256* %copy_src_310, align 4
//CHECK-NEXT:   store i256 %copy_val_312, i256* %copy_dst_311, align 4
//CHECK-NEXT:   %copy_src_413 = getelementptr i256, i256* %4, i32 4
//CHECK-NEXT:   %copy_dst_414 = getelementptr i256, i256* %3, i32 4
//CHECK-NEXT:   %copy_val_415 = load i256, i256* %copy_src_413, align 4
//CHECK-NEXT:   store i256 %copy_val_415, i256* %copy_dst_414, align 4
//CHECK-NEXT:   %copy_src_516 = getelementptr i256, i256* %4, i32 5
//CHECK-NEXT:   %copy_dst_517 = getelementptr i256, i256* %3, i32 5
//CHECK-NEXT:   %copy_val_518 = load i256, i256* %copy_src_516, align 4
//CHECK-NEXT:   store i256 %copy_val_518, i256* %copy_dst_517, align 4
//CHECK-NEXT:   %5 = bitcast [15 x i256]* %sum_0_arena to i256*
//CHECK-NEXT:   %call.sum_0 = call i256 @sum_0(i256* %5)
//CHECK-NEXT:   %6 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 0
//CHECK-NEXT:   store i256 %call.sum_0, i256* %6, align 4
//CHECK-NEXT:   br label %prologue
