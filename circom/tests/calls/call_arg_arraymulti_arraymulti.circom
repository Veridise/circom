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
//CHECK-NEXT:   %1 = getelementptr i256, i256* %0, i32 12
//CHECK-NEXT:   store i256 0, i256* %1, align 4
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY:
//CHECK-NEXT: store2:
//CHECK-NEXT:   %2 = getelementptr i256, i256* %0, i32 13
//CHECK-NEXT:   store i256 0, i256* %2, align 4
//CHECK-NEXT:   br label %loop3
//CHECK-EMPTY:
//CHECK-NEXT: loop3:
//CHECK-NEXT:   br label %loop.cond
//CHECK-EMPTY:
//CHECK-NEXT: loop.cond:
//CHECK-NEXT:   %3 = getelementptr i256, i256* %0, i32 13
//CHECK-NEXT:   %4 = load i256, i256* %3, align 4
//CHECK-NEXT:   %call.fr_lt = call i1 @fr_lt(i256 %4, i256 3)
//CHECK-NEXT:   br i1 %call.fr_lt, label %loop.body, label %loop.end
//CHECK-EMPTY:
//CHECK-NEXT: loop.body:
//CHECK-NEXT:   %5 = getelementptr i256, i256* %0, i32 14
//CHECK-NEXT:   store i256 0, i256* %5, align 4
//CHECK-NEXT:   br label %loop.cond1
//CHECK-EMPTY:
//CHECK-NEXT: loop.end:
//CHECK-NEXT:   br label %return10
//CHECK-EMPTY:
//CHECK-NEXT: loop.cond1:
//CHECK-NEXT:   %6 = getelementptr i256, i256* %0, i32 14
//CHECK-NEXT:   %7 = load i256, i256* %6, align 4
//CHECK-NEXT:   %call.fr_lt4 = call i1 @fr_lt(i256 %7, i256 2)
//CHECK-NEXT:   br i1 %call.fr_lt4, label %loop.body2, label %loop.end3
//CHECK-EMPTY:
//CHECK-NEXT: loop.body2:
//CHECK-NEXT:   %8 = getelementptr i256, i256* %0, i32 12
//CHECK-NEXT:   %9 = load i256, i256* %8, align 4
//CHECK-NEXT:   %10 = getelementptr i256, i256* %0, i32 13
//CHECK-NEXT:   %11 = load i256, i256* %10, align 4
//CHECK-NEXT:   %call.fr_cast_to_addr = call i32 @fr_cast_to_addr(i256 %11)
//CHECK-NEXT:   %mul_addr = mul i32 2, %call.fr_cast_to_addr
//CHECK-NEXT:   %12 = getelementptr i256, i256* %0, i32 14
//CHECK-NEXT:   %13 = load i256, i256* %12, align 4
//CHECK-NEXT:   %call.fr_cast_to_addr5 = call i32 @fr_cast_to_addr(i256 %13)
//CHECK-NEXT:   %mul_addr6 = mul i32 1, %call.fr_cast_to_addr5
//CHECK-NEXT:   %add_addr = add i32 %mul_addr, %mul_addr6
//CHECK-NEXT:   %add_addr7 = add i32 %add_addr, 0
//CHECK-NEXT:   %14 = getelementptr i256, i256* %0, i32 %add_addr7
//CHECK-NEXT:   %15 = load i256, i256* %14, align 4
//CHECK-NEXT:   %16 = getelementptr i256, i256* %0, i32 13
//CHECK-NEXT:   %17 = load i256, i256* %16, align 4
//CHECK-NEXT:   %call.fr_cast_to_addr8 = call i32 @fr_cast_to_addr(i256 %17)
//CHECK-NEXT:   %mul_addr9 = mul i32 2, %call.fr_cast_to_addr8
//CHECK-NEXT:   %18 = getelementptr i256, i256* %0, i32 14
//CHECK-NEXT:   %19 = load i256, i256* %18, align 4
//CHECK-NEXT:   %call.fr_cast_to_addr10 = call i32 @fr_cast_to_addr(i256 %19)
//CHECK-NEXT:   %mul_addr11 = mul i32 1, %call.fr_cast_to_addr10
//CHECK-NEXT:   %add_addr12 = add i32 %mul_addr9, %mul_addr11
//CHECK-NEXT:   %add_addr13 = add i32 %add_addr12, 6
//CHECK-NEXT:   %20 = getelementptr i256, i256* %0, i32 %add_addr13
//CHECK-NEXT:   %21 = load i256, i256* %20, align 4
//CHECK-NEXT:   %call.fr_sub = call i256 @fr_sub(i256 %15, i256 %21)
//CHECK-NEXT:   %call.fr_add = call i256 @fr_add(i256 %9, i256 %call.fr_sub)
//CHECK-NEXT:   %22 = getelementptr i256, i256* %0, i32 12
//CHECK-NEXT:   store i256 %call.fr_add, i256* %22, align 4
//CHECK-NEXT:   %23 = getelementptr i256, i256* %0, i32 14
//CHECK-NEXT:   %24 = load i256, i256* %23, align 4
//CHECK-NEXT:   %call.fr_add14 = call i256 @fr_add(i256 %24, i256 1)
//CHECK-NEXT:   %25 = getelementptr i256, i256* %0, i32 14
//CHECK-NEXT:   store i256 %call.fr_add14, i256* %25, align 4
//CHECK-NEXT:   br label %loop.cond1
//CHECK-EMPTY:
//CHECK-NEXT: loop.end3:
//CHECK-NEXT:   %26 = getelementptr i256, i256* %0, i32 13
//CHECK-NEXT:   %27 = load i256, i256* %26, align 4
//CHECK-NEXT:   %call.fr_add15 = call i256 @fr_add(i256 %27, i256 1)
//CHECK-NEXT:   %28 = getelementptr i256, i256* %0, i32 13
//CHECK-NEXT:   store i256 %call.fr_add15, i256* %28, align 4
//CHECK-NEXT:   br label %loop.cond
//CHECK-EMPTY:
//CHECK-NEXT: return10:
//CHECK-NEXT:   %29 = getelementptr i256, i256* %0, i32 12
//CHECK-NEXT:   %30 = load i256, i256* %29, align 4
//CHECK-NEXT:   ret i256 %30
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
//CHECK-NEXT:   %1 = getelementptr [15 x i256], [15 x i256]* %sum_0_arena, i32 0, i32 0
//CHECK-NEXT:   %2 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 1
//CHECK-NEXT:   call void @fr_copy_n(i256* %2, i256* %1, i32 6)
//CHECK-NEXT:   %3 = getelementptr [15 x i256], [15 x i256]* %sum_0_arena, i32 0, i32 6
//CHECK-NEXT:   %4 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 7
//CHECK-NEXT:   call void @fr_copy_n(i256* %4, i256* %3, i32 6)
//CHECK-NEXT:   %5 = bitcast [15 x i256]* %sum_0_arena to i256*
//CHECK-NEXT:   %call.sum_0 = call i256 @sum_0(i256* %5)
//CHECK-NEXT:   %6 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 0
//CHECK-NEXT:   store i256 %call.sum_0, i256* %6, align 4
//CHECK-NEXT:   br label %prologue
//CHECK-EMPTY:
//CHECK-NEXT: prologue:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
