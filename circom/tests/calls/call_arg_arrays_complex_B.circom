pragma circom 2.1.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

function sum(a, b) {
    b[0] = a[1];
    b[1] = a[0];
    return b;
}

template CallArgTest() {
    signal input x[2][3];
    signal output z[2][3];

    var y[2][3];
    z <-- sum(x, y);
}

component main = CallArgTest();

//CHECK-LABEL: define{{.*}} i256* @sum_0(i256* %0){{.*}} {
//CHECK:      store1:
//CHECK:        %3 = getelementptr i256, i256* %0, i32 6
//CHECK-NEXT:   %4 = getelementptr i256, i256* %0, i32 3
//CHECK-NEXT:   call void @fr_copy_n(i256* %4, i256* %3, i32 3)
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY:
//CHECK:      store2:
//CHECK:        %7 = getelementptr i256, i256* %0, i32 9
//CHECK-NEXT:   %8 = getelementptr i256, i256* %0, i32 0
//CHECK-NEXT:   call void @fr_copy_n(i256* %8, i256* %7, i32 3)
//CHECK-NEXT:   br label %return3
//CHECK-EMPTY:
//CHECK-NEXT: return3:
//CHECK-NEXT:   %9 = getelementptr i256, i256* %0, i32 6
//CHECK-NEXT:   ret i256* %9
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @CallArgTest_0_run([0 x i256]* %0){{.*}} {
//CHECK-NEXT: prelude:
//CHECK-NEXT:   %lvars = alloca [9 x i256], align 8
//CHECK-NEXT:   %subcmps = alloca [0 x { [0 x i256]*, i32 }], align 8
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY:
//CHECK-NEXT: store1:
//CHECK-NEXT:   %1 = getelementptr [9 x i256], [9 x i256]* %lvars, i32 0, i32 6
//CHECK-NEXT:   store i256 0, i256* %1, align 4
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY:
//CHECK-NEXT: store2:
//CHECK-NEXT:   %2 = getelementptr [9 x i256], [9 x i256]* %lvars, i32 0, i32 7
//CHECK-NEXT:   store i256 0, i256* %2, align 4
//CHECK-NEXT:   br label %store3
//CHECK-EMPTY:
//CHECK-NEXT: store3:
//CHECK-NEXT:   %3 = getelementptr [9 x i256], [9 x i256]* %lvars, i32 0, i32 8
//CHECK-NEXT:   store i256 0, i256* %3, align 4
//CHECK-NEXT:   br label %store4
//CHECK-EMPTY:
//CHECK-NEXT: store4:
//CHECK-NEXT:   %4 = getelementptr [9 x i256], [9 x i256]* %lvars, i32 0, i32 6
//CHECK-NEXT:   %5 = load i256, i256* %4, align 4
//CHECK-NEXT:   %6 = getelementptr [9 x i256], [9 x i256]* %lvars, i32 0, i32 0
//CHECK-NEXT:   %7 = getelementptr [9 x i256], [9 x i256]* %lvars, i32 0, i32 6
//CHECK-NEXT:   call void @fr_copy_n(i256* %7, i256* %6, i32 3)
//CHECK-NEXT:   br label %store5
//CHECK-EMPTY:
//CHECK-NEXT: store5:
//CHECK-NEXT:   %8 = getelementptr [9 x i256], [9 x i256]* %lvars, i32 0, i32 6
//CHECK-NEXT:   %9 = load i256, i256* %8, align 4
//CHECK-NEXT:   %10 = getelementptr [9 x i256], [9 x i256]* %lvars, i32 0, i32 3
//CHECK-NEXT:   %11 = getelementptr [9 x i256], [9 x i256]* %lvars, i32 0, i32 6
//CHECK-NEXT:   call void @fr_copy_n(i256* %11, i256* %10, i32 3)
//CHECK-NEXT:   br label %call6
//CHECK-EMPTY:
//CHECK-NEXT: call6:
//CHECK-NEXT:   %sum_0_arena = alloca [12 x i256], align 8
//CHECK-NEXT:   %12 = getelementptr [12 x i256], [12 x i256]* %sum_0_arena, i32 0, i32 0
//CHECK-NEXT:   %13 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 6
//CHECK-NEXT:   call void @fr_copy_n(i256* %13, i256* %12, i32 6)
//CHECK-NEXT:   %14 = getelementptr [12 x i256], [12 x i256]* %sum_0_arena, i32 0, i32 6
//CHECK-NEXT:   %15 = getelementptr [9 x i256], [9 x i256]* %lvars, i32 0, i32 0
//CHECK-NEXT:   call void @fr_copy_n(i256* %15, i256* %14, i32 6)
//CHECK-NEXT:   %16 = bitcast [12 x i256]* %sum_0_arena to i256*
//CHECK-NEXT:   %call.sum_0 = call i256* @sum_0(i256* %16)
//CHECK-NEXT:   %17 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 0
//CHECK-NEXT:   call void @fr_copy_n(i256* %call.sum_0, i256* %17, i32 6)
//CHECK-NEXT:   br label %prologue
//CHECK-EMPTY:
//CHECK-NEXT: prologue:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
