pragma circom 2.1.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

function sum(a, b, c, d) {
    if (a < 7) {
        return b;
    } else if (a > 12) {
        return c;
    } else {
        return d;
    }
}

template CallArgTest() {
    signal input a;
    signal input b[2][3];
    signal input c[2][3];
    signal input d[2][3];
    signal output z[2][3];

    z <-- sum(a, b, c, d);
}

component main = CallArgTest();

//CHECK-LABEL: define{{.*}} i256* @sum_0(i256* %0){{.*}} {
//CHECK-NEXT: sum_0:
//CHECK-NEXT:   br label %branch1
//CHECK-EMPTY:
//CHECK-NEXT: branch1:
//CHECK-NEXT:   %1 = getelementptr i256, i256* %0, i32 0
//CHECK-NEXT:   %2 = load i256, i256* %1, align 4
//CHECK-NEXT:   %call.fr_lt = call i1 @fr_lt(i256 %2, i256 7)
//CHECK-NEXT:   br i1 %call.fr_lt, label %if.then, label %if.else
//CHECK-EMPTY:
//CHECK-NEXT: if.then:
//CHECK-NEXT:   %3 = getelementptr i256, i256* %0, i32 1
//CHECK-NEXT:   ret i256* %3
//CHECK-EMPTY:
//CHECK-NEXT: if.else:
//CHECK-NEXT:   %4 = getelementptr i256, i256* %0, i32 0
//CHECK-NEXT:   %5 = load i256, i256* %4, align 4
//CHECK-NEXT:   %call.fr_gt = call i1 @fr_gt(i256 %5, i256 12)
//CHECK-NEXT:   br i1 %call.fr_gt, label %if.then1, label %if.else2
//CHECK-EMPTY:
//CHECK-NEXT: if.merge:
//CHECK-NEXT:   unreachable
//CHECK-EMPTY:
//CHECK-NEXT: if.then1:
//CHECK-NEXT:   %6 = getelementptr i256, i256* %0, i32 7
//CHECK-NEXT:   ret i256* %6
//CHECK-EMPTY:
//CHECK-NEXT: if.else2:
//CHECK-NEXT:   %7 = getelementptr i256, i256* %0, i32 13
//CHECK-NEXT:   ret i256* %7
//CHECK-EMPTY:
//CHECK-NEXT: if.merge3:
//CHECK-NEXT:   unreachable
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @CallArgTest_0_run([0 x i256]* %0){{.*}} {
//CHECK-NEXT: prelude:
//CHECK-NEXT:   %lvars = alloca [0 x i256], align 8
//CHECK-NEXT:   %subcmps = alloca [0 x { [0 x i256]*, i32 }], align 8
//CHECK-NEXT:   br label %call1
//CHECK-EMPTY:
//CHECK-NEXT: call1:
//CHECK-NEXT:   %sum_0_arena = alloca [19 x i256], align 8
//CHECK-NEXT:   %1 = getelementptr [19 x i256], [19 x i256]* %sum_0_arena, i32 0, i32 0
//CHECK-NEXT:   %2 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 6
//CHECK-NEXT:   %3 = load i256, i256* %2, align 4
//CHECK-NEXT:   store i256 %3, i256* %1, align 4
//CHECK-NEXT:   %4 = getelementptr [19 x i256], [19 x i256]* %sum_0_arena, i32 0, i32 1
//CHECK-NEXT:   %5 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 7
//CHECK-NEXT:   call void @fr_copy_n(i256* %5, i256* %4, i32 6)
//CHECK-NEXT:   %6 = getelementptr [19 x i256], [19 x i256]* %sum_0_arena, i32 0, i32 7
//CHECK-NEXT:   %7 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 13
//CHECK-NEXT:   call void @fr_copy_n(i256* %7, i256* %6, i32 6)
//CHECK-NEXT:   %8 = getelementptr [19 x i256], [19 x i256]* %sum_0_arena, i32 0, i32 13
//CHECK-NEXT:   %9 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 19
//CHECK-NEXT:   call void @fr_copy_n(i256* %9, i256* %8, i32 6)
//CHECK-NEXT:   %10 = bitcast [19 x i256]* %sum_0_arena to i256*
//CHECK-NEXT:   %call.sum_0 = call i256* @sum_0(i256* %10)
//CHECK-NEXT:   %11 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 0
//CHECK-NEXT:   call void @fr_copy_n(i256* %call.sum_0, i256* %11, i32 6)
//CHECK-NEXT:   br label %prologue
//CHECK-EMPTY:
//CHECK-NEXT: prologue:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
