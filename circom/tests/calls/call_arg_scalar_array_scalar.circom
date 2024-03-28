pragma circom 2.1.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

function sum(x, a, y) {
    return x + a[0] + a[1] + a[2] + a[3] + y;
}

template CallArgTest() {
    signal input x[4];
    signal output y;

    y <-- sum(77, x, 99);
}

component main = CallArgTest();

//CHECK-LABEL: define{{.*}} i256 @sum_0(i256* %0){{.*}} {
//CHECK-NEXT: sum_0:
//CHECK-NEXT:   br label %return1
//CHECK-EMPTY:
//CHECK-NEXT: return1:
//CHECK-NEXT:   %1 = getelementptr i256, i256* %0, i32 0
//CHECK-NEXT:   %2 = load i256, i256* %1, align 4
//CHECK-NEXT:   %3 = getelementptr i256, i256* %0, i32 1
//CHECK-NEXT:   %4 = load i256, i256* %3, align 4
//CHECK-NEXT:   %call.fr_add = call i256 @fr_add(i256 %2, i256 %4)
//CHECK-NEXT:   %5 = getelementptr i256, i256* %0, i32 2
//CHECK-NEXT:   %6 = load i256, i256* %5, align 4
//CHECK-NEXT:   %call.fr_add1 = call i256 @fr_add(i256 %call.fr_add, i256 %6)
//CHECK-NEXT:   %7 = getelementptr i256, i256* %0, i32 3
//CHECK-NEXT:   %8 = load i256, i256* %7, align 4
//CHECK-NEXT:   %call.fr_add2 = call i256 @fr_add(i256 %call.fr_add1, i256 %8)
//CHECK-NEXT:   %9 = getelementptr i256, i256* %0, i32 4
//CHECK-NEXT:   %10 = load i256, i256* %9, align 4
//CHECK-NEXT:   %call.fr_add3 = call i256 @fr_add(i256 %call.fr_add2, i256 %10)
//CHECK-NEXT:   %11 = getelementptr i256, i256* %0, i32 5
//CHECK-NEXT:   %12 = load i256, i256* %11, align 4
//CHECK-NEXT:   %call.fr_add4 = call i256 @fr_add(i256 %call.fr_add3, i256 %12)
//CHECK-NEXT:   ret i256 %call.fr_add4
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @CallArgTest_{{[0-9]+}}_run
//CHECK-SAME: ([0 x i256]* %[[ARG:[0-9]+]]){{.*}} {
//CHECK:      call1:
//CHECK-NEXT:   %[[ARENA:sum_.*_arena]] = alloca [6 x i256]
//CHECK-NEXT:   %[[X_PTR:[0-9]+]] = getelementptr [6 x i256], [6 x i256]* %[[ARENA]], i32 0, i32 0
//CHECK-NEXT:   store i256 77, i256* %[[X_PTR]]
//CHECK-NEXT:   %[[DST:[0-9]+]] = getelementptr [6 x i256], [6 x i256]* %[[ARENA]], i32 0, i32 1
//CHECK-NEXT:   %[[SRC:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i32 1
//CHECK-NEXT:   call void @fr_copy_n(i256* %[[SRC]], i256* %[[DST]], i32 4)
//CHECK-NEXT:   %[[Y_PTR:[0-9]+]] = getelementptr [6 x i256], [6 x i256]* %[[ARENA]], i32 0, i32 5
//CHECK-NEXT:   store i256 99, i256* %[[Y_PTR]]
//CHECK-NEXT:   %[[ARENA_PTR:.*]] = bitcast [6 x i256]* %[[ARENA]] to i256*
//CHECK-NEXT:   %call.[[SUM:sum_[0-9]+]] = call i256 @[[SUM]](i256* %[[ARENA_PTR]])
//CHECK-NEXT:   %[[OUT:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %[[ARG]], i32 0, i32 0
//CHECK-NEXT:   store i256 %call.[[SUM]], i256* %[[OUT]]
//CHECK-NEXT:   br label %prologue
