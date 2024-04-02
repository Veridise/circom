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
//CHECK-NEXT:   br label %loop3
//CHECK-EMPTY:
//CHECK-NEXT: loop3:
//CHECK-NEXT:   br label %loop.cond
//CHECK-EMPTY:
//CHECK-NEXT: loop.cond:
//CHECK-NEXT:   %[[T03:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %0, i32 13
//CHECK-NEXT:   %[[T04:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T03]], align 4
//CHECK-NEXT:   %call.fr_lt = call i1 @fr_lt(i256 %[[T04]], i256 3)
//CHECK-NEXT:   br i1 %call.fr_lt, label %loop.body, label %loop.end
//CHECK-EMPTY:
//CHECK-NEXT: loop.body:
//CHECK-NEXT:   %[[T05:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %0, i32 14
//CHECK-NEXT:   store i256 0, i256* %[[T05]], align 4
//CHECK-NEXT:   br label %loop.cond1
//CHECK-EMPTY:
//CHECK-NEXT: loop.end:
//CHECK-NEXT:   br label %return10
//CHECK-EMPTY:
//CHECK-NEXT: loop.cond1:
//CHECK-NEXT:   %[[T06:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %0, i32 14
//CHECK-NEXT:   %[[T07:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T06]], align 4
//CHECK-NEXT:   %call.fr_lt4 = call i1 @fr_lt(i256 %[[T07]], i256 2)
//CHECK-NEXT:   br i1 %call.fr_lt4, label %loop.body2, label %loop.end3
//CHECK-EMPTY:
//CHECK-NEXT: loop.body2:
//CHECK-NEXT:   %[[T22:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %0, i32 12
//CHECK-NEXT:   %[[T08:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %0, i32 12
//CHECK-NEXT:   %[[T09:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T08]], align 4
//CHECK-NEXT:   %[[T10:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %0, i32 13
//CHECK-NEXT:   %[[T11:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T10]], align 4
//CHECK-NEXT:   %call.fr_cast_to_addr = call i32 @fr_cast_to_addr(i256 %[[T11]])
//CHECK-NEXT:   %mul_addr = mul i32 2, %call.fr_cast_to_addr
//CHECK-NEXT:   %[[T12:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %0, i32 14
//CHECK-NEXT:   %[[T13:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T12]], align 4
//CHECK-NEXT:   %call.fr_cast_to_addr5 = call i32 @fr_cast_to_addr(i256 %[[T13]])
//CHECK-NEXT:   %mul_addr6 = mul i32 1, %call.fr_cast_to_addr5
//CHECK-NEXT:   %add_addr = add i32 %mul_addr, %mul_addr6
//CHECK-NEXT:   %add_addr7 = add i32 %add_addr, 0
//CHECK-NEXT:   %[[T14:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %0, i32 %add_addr7
//CHECK-NEXT:   %[[T15:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T14]], align 4
//CHECK-NEXT:   %[[T16:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %0, i32 13
//CHECK-NEXT:   %[[T17:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T16]], align 4
//CHECK-NEXT:   %call.fr_cast_to_addr8 = call i32 @fr_cast_to_addr(i256 %[[T17]])
//CHECK-NEXT:   %mul_addr9 = mul i32 2, %call.fr_cast_to_addr8
//CHECK-NEXT:   %[[T18:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %0, i32 14
//CHECK-NEXT:   %[[T19:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T18]], align 4
//CHECK-NEXT:   %call.fr_cast_to_addr10 = call i32 @fr_cast_to_addr(i256 %[[T19]])
//CHECK-NEXT:   %mul_addr11 = mul i32 1, %call.fr_cast_to_addr10
//CHECK-NEXT:   %add_addr12 = add i32 %mul_addr9, %mul_addr11
//CHECK-NEXT:   %add_addr13 = add i32 %add_addr12, 6
//CHECK-NEXT:   %[[T20:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %0, i32 %add_addr13
//CHECK-NEXT:   %[[T21:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T20]], align 4
//CHECK-NEXT:   %call.fr_sub = call i256 @fr_sub(i256 %[[T15]], i256 %[[T21]])
//CHECK-NEXT:   %call.fr_add = call i256 @fr_add(i256 %[[T09]], i256 %call.fr_sub)
//CHECK-NEXT:   store i256 %call.fr_add, i256* %[[T22]], align 4
//CHECK-NEXT:   %[[T25:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %0, i32 14
//CHECK-NEXT:   %[[T23:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %0, i32 14
//CHECK-NEXT:   %[[T24:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T23]], align 4
//CHECK-NEXT:   %call.fr_add14 = call i256 @fr_add(i256 %[[T24]], i256 1)
//CHECK-NEXT:   store i256 %call.fr_add14, i256* %[[T25]], align 4
//CHECK-NEXT:   br label %loop.cond1
//CHECK-EMPTY:
//CHECK-NEXT: loop.end3:
//CHECK-NEXT:   %[[T28:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %0, i32 13
//CHECK-NEXT:   %[[T26:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %0, i32 13
//CHECK-NEXT:   %[[T27:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T26]], align 4
//CHECK-NEXT:   %call.fr_add15 = call i256 @fr_add(i256 %[[T27]], i256 1)
//CHECK-NEXT:   store i256 %call.fr_add15, i256* %[[T28]], align 4
//CHECK-NEXT:   br label %loop.cond
//CHECK-EMPTY:
//CHECK-NEXT: return10:
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
