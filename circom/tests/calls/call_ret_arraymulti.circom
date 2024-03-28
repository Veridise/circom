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
//CHECK-NEXT:   %1 = getelementptr i256, i256* %0, i32 0
//CHECK-NEXT:   %2 = load i256, i256* %1, align 4
//CHECK-NEXT:   %3 = getelementptr i256, i256* %0, i32 24
//CHECK-NEXT:   %4 = getelementptr i256, i256* %0, i32 0
//CHECK-NEXT:   call void @fr_copy_n(i256* %4, i256* %3, i32 24)
//CHECK-NEXT:   br label %return2
//CHECK-EMPTY:
//CHECK-NEXT: return2:
//CHECK-NEXT:   %5 = getelementptr i256, i256* %0, i32 24
//CHECK-NEXT:   ret i256* %5
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
//CHECK-NEXT:   %1 = getelementptr [48 x i256], [48 x i256]* %sum_0_arena, i32 0, i32 0
//CHECK-NEXT:   %2 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 24
//CHECK-NEXT:   call void @fr_copy_n(i256* %2, i256* %1, i32 24)
//CHECK-NEXT:   %3 = bitcast [48 x i256]* %sum_0_arena to i256*
//CHECK-NEXT:   %call.sum_0 = call i256* @sum_0(i256* %3)
//CHECK-NEXT:   %4 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 0
//CHECK-NEXT:   call void @fr_copy_n(i256* %call.sum_0, i256* %4, i32 24)
//CHECK-NEXT:   br label %prologue
//CHECK-EMPTY:
//CHECK-NEXT: prologue:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
