pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s

function sum(a, b) {
    return a[0] + a[1] + a[2] + a[3] + b[0] + b[1];
}

template CallWithArrayAndArray() {
    signal input x[4];
    signal input y[2];
    signal output z;

    z <-- sum(x, y);
}

component main = CallWithArrayAndArray();

//CHECK-LABEL: define{{.*}} void @CallWithArrayAndArray_{{[0-9]+}}_run([0 x i256]* %0){{.*}} {
//CHECK-NEXT: prelude:
//CHECK-NEXT:   %lvars = alloca [0 x i256], align 8
//CHECK-NEXT:   %subcmps = alloca [0 x { [0 x i256]*, i32 }], align 8
//CHECK-NEXT:   br label %call1
//CHECK-EMPTY: 
//CHECK-NEXT: call1:
//CHECK-NEXT:   %sum_0_arena = alloca [6 x i256], align 8
//CHECK-NEXT:   %1 = getelementptr [6 x i256], [6 x i256]* %sum_0_arena, i32 0, i32 0
//CHECK-NEXT:   %2 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 1
//CHECK-NEXT:   call void @fr_copy_n(i256* %2, i256* %1, i32 4)
//CHECK-NEXT:   %3 = getelementptr [6 x i256], [6 x i256]* %sum_0_arena, i32 0, i32 4
//CHECK-NEXT:   %4 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 5
//CHECK-NEXT:   call void @fr_copy_n(i256* %4, i256* %3, i32 2)
//CHECK-NEXT:   %5 = bitcast [6 x i256]* %sum_0_arena to i256*
//CHECK-NEXT:   %call.sum_0 = call i256 @sum_0(i256* %5)
//CHECK-NEXT:   %6 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 0
//CHECK-NEXT:   store i256 %call.sum_0, i256* %6, align 4
//CHECK-NEXT:   br label %prologue
//CHECK-EMPTY: 
//CHECK-NEXT: prologue:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
