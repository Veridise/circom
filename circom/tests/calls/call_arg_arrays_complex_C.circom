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
//CHECK-NEXT:   %9 = getelementptr i256, i256* %0, i32 0
//CHECK-NEXT:   %10 = load i256, i256* %9, align 4
//CHECK-NEXT:   ret i256 %10
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
//CHECK-NEXT:   %1 = getelementptr [12 x i256], [12 x i256]* %sum_0_arena, i32 0, i32 0
//CHECK-NEXT:   %2 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 7
//CHECK-NEXT:   call void @fr_copy_n(i256* %2, i256* %1, i32 6)
//CHECK-NEXT:   %3 = getelementptr [12 x i256], [12 x i256]* %sum_0_arena, i32 0, i32 6
//CHECK-NEXT:   %4 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 13
//CHECK-NEXT:   call void @fr_copy_n(i256* %4, i256* %3, i32 6)
//CHECK-NEXT:   %5 = bitcast [12 x i256]* %sum_0_arena to i256*
//CHECK-NEXT:   %call.sum_0 = call i256 @sum_0(i256* %5)
//CHECK-NEXT:   %6 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 6
//CHECK-NEXT:   store i256 %call.sum_0, i256* %6, align 4
//CHECK-NEXT:   br label %prologue
//CHECK-EMPTY: 
//CHECK-NEXT: prologue:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
