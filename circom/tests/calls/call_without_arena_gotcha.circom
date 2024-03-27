pragma circom 2.1.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

function overwrite(a, b) {
    a[0] = b[1];
    a[1] = b[0];
    return a[0] + a[1];
}

template Gotcha() {
    signal input x[2];
    signal input y[2];
    signal output p;
    log(x[0]);
    p <== overwrite(x, y);
    log(x[0]);
}

component main = Gotcha();

//CHECK-LABEL: define{{.*}} i256 @overwrite_0(i256* %0){{.*}} {
//CHECK-NEXT: overwrite_0:
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY:
//CHECK-NEXT: store1:
//CHECK-NEXT:   %1 = getelementptr i256, i256* %0, i32 3
//CHECK-NEXT:   %2 = load i256, i256* %1, align 4
//CHECK-NEXT:   %3 = getelementptr i256, i256* %0, i32 0
//CHECK-NEXT:   store i256 %2, i256* %3, align 4
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY:
//CHECK-NEXT: store2:
//CHECK-NEXT:   %4 = getelementptr i256, i256* %0, i32 2
//CHECK-NEXT:   %5 = load i256, i256* %4, align 4
//CHECK-NEXT:   %6 = getelementptr i256, i256* %0, i32 1
//CHECK-NEXT:   store i256 %5, i256* %6, align 4
//CHECK-NEXT:   br label %return3
//CHECK-EMPTY:
//CHECK-NEXT: return3:
//CHECK-NEXT:   %7 = getelementptr i256, i256* %0, i32 0
//CHECK-NEXT:   %8 = load i256, i256* %7, align 4
//CHECK-NEXT:   %9 = getelementptr i256, i256* %0, i32 1
//CHECK-NEXT:   %10 = load i256, i256* %9, align 4
//CHECK-NEXT:   %call.fr_add = call i256 @fr_add(i256 %8, i256 %10)
//CHECK-NEXT:   ret i256 %call.fr_add
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @Gotcha_0_run([0 x i256]* %0){{.*}} {
//CHECK-NEXT: prelude:
//CHECK-NEXT:   %lvars = alloca [0 x i256], align 8
//CHECK-NEXT:   %subcmps = alloca [0 x { [0 x i256]*, i32 }], align 8
//CHECK-NEXT:   br label %log1
//CHECK-EMPTY:
//CHECK-NEXT: log1:
//CHECK-NEXT:   br label %call2
//CHECK-EMPTY:
//CHECK-NEXT: call2:
//CHECK-NEXT:   %overwrite_0_arena = alloca [4 x i256], align 8
//CHECK-NEXT:   %1 = getelementptr [4 x i256], [4 x i256]* %overwrite_0_arena, i32 0, i32 0
//CHECK-NEXT:   %2 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 1
//CHECK-NEXT:   call void @fr_copy_n(i256* %2, i256* %1, i32 2)
//CHECK-NEXT:   %3 = getelementptr [4 x i256], [4 x i256]* %overwrite_0_arena, i32 0, i32 2
//CHECK-NEXT:   %4 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 3
//CHECK-NEXT:   call void @fr_copy_n(i256* %4, i256* %3, i32 2)
//CHECK-NEXT:   %5 = bitcast [4 x i256]* %overwrite_0_arena to i256*
//CHECK-NEXT:   %call.overwrite_0 = call i256 @overwrite_0(i256* %5)
//CHECK-NEXT:   %6 = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 0
//CHECK-NEXT:   store i256 %call.overwrite_0, i256* %6, align 4
//CHECK-NEXT:   %7 = load i256, i256* %6, align 4
//CHECK-NEXT:   %constraint = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %call.overwrite_0, i256 %7, i1* %constraint)
//CHECK-NEXT:   br label %log3
//CHECK-EMPTY:
//CHECK-NEXT: log3:
//CHECK-NEXT:   br label %prologue
//CHECK-EMPTY:
//CHECK-NEXT: prologue:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
