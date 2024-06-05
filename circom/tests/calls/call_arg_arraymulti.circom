pragma circom 2.1.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

function sum(a) {
    var agg = 0;
    for (var i = 0; i < 3; i++) {
        for (var j = 0; j < 2; j++) {
            agg += a[i][j];
        }
    }
    return agg;
}

template CallArgTest() {
    signal input x[3][2];
    signal output y;

    y <-- sum(x);
}

component main = CallArgTest();

//CHECK-LABEL: define{{.*}} void @..generated..loop.body.{{[0-9]+}}([0 x i256]* %lvars, [0 x i256]* %signals, i256* %var_0){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_1:[0-9]+]]:
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %[[T01:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 6
//CHECK-NEXT:   %[[T02:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 6
//CHECK-NEXT:   %[[T03:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T02]], align 4
//CHECK-NEXT:   %[[T04:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %var_0, i32 0
//CHECK-NEXT:   %[[T05:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T04]], align 4
//CHECK-NEXT:   %[[T06:[0-9a-zA-Z_.]+]] = call i256 @fr_add(i256 %[[T03]], i256 %[[T05]])
//CHECK-NEXT:   store i256 %[[T06]], i256* %[[T01]], align 4
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %[[T07:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 8
//CHECK-NEXT:   %[[T08:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 8
//CHECK-NEXT:   %[[T09:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T08]], align 4
//CHECK-NEXT:   %[[T10:[0-9a-zA-Z_.]+]] = call i256 @fr_add(i256 %[[T09]], i256 1)
//CHECK-NEXT:   store i256 %[[T10]], i256* %[[T07]], align 4
//CHECK-NEXT:   br label %return3
//CHECK-EMPTY: 
//CHECK-NEXT: return3:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }

//CHECK-LABEL: define{{.*}} i256 @sum_0(i256* %0){{.*}} {
//CHECK-NEXT: sum_0:
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY:
//CHECK-NEXT: store1:
//CHECK-NEXT:   %[[T01:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %0, i32 6
//CHECK-NEXT:   store i256 0, i256* %[[T01]], align 4
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY:
//CHECK-NEXT: store2:
//CHECK-NEXT:   %[[T02:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %0, i32 7
//CHECK-NEXT:   store i256 0, i256* %[[T02]], align 4
//CHECK-NEXT:   br label %unrolled_loop3
//CHECK-EMPTY:
//CHECK-NEXT: unrolled_loop3:
//CHECK-NEXT:   %3 = getelementptr i256, i256* %0, i32 8
//CHECK-NEXT:   store i256 0, i256* %3, align 4
//CHECK-NEXT:   %4 = bitcast i256* %0 to [0 x i256]*
//CHECK-NEXT:   %5 = bitcast i256* %0 to [0 x i256]*
//CHECK-NEXT:   %6 = getelementptr [0 x i256], [0 x i256]* %5, i32 0, i256 0
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %4, [0 x i256]* null, i256* %6)
//CHECK-NEXT:   %7 = bitcast i256* %0 to [0 x i256]*
//CHECK-NEXT:   %8 = bitcast i256* %0 to [0 x i256]*
//CHECK-NEXT:   %9 = getelementptr [0 x i256], [0 x i256]* %8, i32 0, i256 1
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %7, [0 x i256]* null, i256* %9)
//CHECK-NEXT:   %10 = getelementptr i256, i256* %0, i32 7
//CHECK-NEXT:   %11 = getelementptr i256, i256* %0, i32 7
//CHECK-NEXT:   %12 = load i256, i256* %11, align 4
//CHECK-NEXT:   %call.fr_add = call i256 @fr_add(i256 %12, i256 1)
//CHECK-NEXT:   store i256 %call.fr_add, i256* %10, align 4
//CHECK-NEXT:   %13 = getelementptr i256, i256* %0, i32 8
//CHECK-NEXT:   store i256 0, i256* %13, align 4
//CHECK-NEXT:   %14 = bitcast i256* %0 to [0 x i256]*
//CHECK-NEXT:   %15 = bitcast i256* %0 to [0 x i256]*
//CHECK-NEXT:   %16 = getelementptr [0 x i256], [0 x i256]* %15, i32 0, i256 2
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %14, [0 x i256]* null, i256* %16)
//CHECK-NEXT:   %17 = bitcast i256* %0 to [0 x i256]*
//CHECK-NEXT:   %18 = bitcast i256* %0 to [0 x i256]*
//CHECK-NEXT:   %19 = getelementptr [0 x i256], [0 x i256]* %18, i32 0, i256 3
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %17, [0 x i256]* null, i256* %19)
//CHECK-NEXT:   %20 = getelementptr i256, i256* %0, i32 7
//CHECK-NEXT:   %21 = getelementptr i256, i256* %0, i32 7
//CHECK-NEXT:   %22 = load i256, i256* %21, align 4
//CHECK-NEXT:   %call.fr_add10 = call i256 @fr_add(i256 %22, i256 1)
//CHECK-NEXT:   store i256 %call.fr_add10, i256* %20, align 4
//CHECK-NEXT:   %23 = getelementptr i256, i256* %0, i32 8
//CHECK-NEXT:   store i256 0, i256* %23, align 4
//CHECK-NEXT:   %24 = bitcast i256* %0 to [0 x i256]*
//CHECK-NEXT:   %25 = bitcast i256* %0 to [0 x i256]*
//CHECK-NEXT:   %26 = getelementptr [0 x i256], [0 x i256]* %25, i32 0, i256 4
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %24, [0 x i256]* null, i256* %26)
//CHECK-NEXT:   %27 = bitcast i256* %0 to [0 x i256]*
//CHECK-NEXT:   %28 = bitcast i256* %0 to [0 x i256]*
//CHECK-NEXT:   %29 = getelementptr [0 x i256], [0 x i256]* %28, i32 0, i256 5
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %27, [0 x i256]* null, i256* %29)
//CHECK-NEXT:   %30 = getelementptr i256, i256* %0, i32 7
//CHECK-NEXT:   %31 = getelementptr i256, i256* %0, i32 7
//CHECK-NEXT:   %32 = load i256, i256* %31, align 4
//CHECK-NEXT:   %call.fr_add17 = call i256 @fr_add(i256 %32, i256 1)
//CHECK-NEXT:   store i256 %call.fr_add17, i256* %30, align 4
//CHECK-NEXT:   br label %return4
//CHECK-EMPTY:
//CHECK-NEXT: return4:
//CHECK-NEXT:   %[[T33:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %0, i32 6
//CHECK-NEXT:   %[[T34:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T33]], align 4
//CHECK-NEXT:   ret i256 %[[T34]]
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @CallArgTest_0_run([0 x i256]* %0){{.*}} {
//CHECK-NEXT: prelude:
//CHECK-NEXT:   %lvars = alloca [0 x i256], align 8
//CHECK-NEXT:   %subcmps = alloca [0 x { [0 x i256]*, i32 }], align 8
//CHECK-NEXT:   br label %call1
//CHECK-EMPTY:
//CHECK-NEXT: call1:
//CHECK-NEXT:   %sum_0_arena = alloca [9 x i256], align 8
//CHECK-NEXT:   %[[SRC_PTR:[0-9a-zA-Z_.]+]] = getelementptr [9 x i256], [9 x i256]* %sum_0_arena, i32 0, i32 0
//CHECK-NEXT:   %[[DST_PTR:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 1
//CHECK-NEXT:   %copy_src_0 = getelementptr i256, i256* %[[DST_PTR]], i32 0
//CHECK-NEXT:   %copy_dst_0 = getelementptr i256, i256* %[[SRC_PTR]], i32 0
//CHECK-NEXT:   %copy_val_0 = load i256, i256* %copy_src_0, align 4
//CHECK-NEXT:   store i256 %copy_val_0, i256* %copy_dst_0, align 4
//CHECK-NEXT:   %copy_src_1 = getelementptr i256, i256* %[[DST_PTR]], i32 1
//CHECK-NEXT:   %copy_dst_1 = getelementptr i256, i256* %[[SRC_PTR]], i32 1
//CHECK-NEXT:   %copy_val_1 = load i256, i256* %copy_src_1, align 4
//CHECK-NEXT:   store i256 %copy_val_1, i256* %copy_dst_1, align 4
//CHECK-NEXT:   %copy_src_2 = getelementptr i256, i256* %[[DST_PTR]], i32 2
//CHECK-NEXT:   %copy_dst_2 = getelementptr i256, i256* %[[SRC_PTR]], i32 2
//CHECK-NEXT:   %copy_val_2 = load i256, i256* %copy_src_2, align 4
//CHECK-NEXT:   store i256 %copy_val_2, i256* %copy_dst_2, align 4
//CHECK-NEXT:   %copy_src_3 = getelementptr i256, i256* %[[DST_PTR]], i32 3
//CHECK-NEXT:   %copy_dst_3 = getelementptr i256, i256* %[[SRC_PTR]], i32 3
//CHECK-NEXT:   %copy_val_3 = load i256, i256* %copy_src_3, align 4
//CHECK-NEXT:   store i256 %copy_val_3, i256* %copy_dst_3, align 4
//CHECK-NEXT:   %copy_src_4 = getelementptr i256, i256* %[[DST_PTR]], i32 4
//CHECK-NEXT:   %copy_dst_4 = getelementptr i256, i256* %[[SRC_PTR]], i32 4
//CHECK-NEXT:   %copy_val_4 = load i256, i256* %copy_src_4, align 4
//CHECK-NEXT:   store i256 %copy_val_4, i256* %copy_dst_4, align 4
//CHECK-NEXT:   %copy_src_5 = getelementptr i256, i256* %[[DST_PTR]], i32 5
//CHECK-NEXT:   %copy_dst_5 = getelementptr i256, i256* %[[SRC_PTR]], i32 5
//CHECK-NEXT:   %copy_val_5 = load i256, i256* %copy_src_5, align 4
//CHECK-NEXT:   store i256 %copy_val_5, i256* %copy_dst_5, align 4
//CHECK-NEXT:   %3 = bitcast [9 x i256]* %sum_0_arena to i256*
//CHECK-NEXT:   %call.sum_0 = call i256 @sum_0(i256* %3)
//CHECK-NEXT:   %4 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 0
//CHECK-NEXT:   store i256 %call.sum_0, i256* %4, align 4
//CHECK-NEXT:   br label %prologue
